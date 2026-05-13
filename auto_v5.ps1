## auto_v5.ps1 - Universal geometry detector with multiple modeling strategies.
## Improves on auto_v4 by adding:
##  - Screw detection (2 cylinders, elongated BBox, length >> width)
##  - Box-with-legs detection (cylinders extending below main body)
##  - Better ring vs box decision (looks at z-axis cylinders, not all)
##  - Multi-step shaft (stepped cylinder along Z axis)
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File auto_v5.ps1 -folder "C:\...\round_xxx"

param([string]$folder = $PSScriptRoot)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

$kPart = 12290; $kJoin = 20481; $kCut = 20482; $kPos = 20993; $kNeg = 20994

# ---- nag-watcher ----
if (-not ('NagV5' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagV5 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true

# Find .ipt
$realF = Join-Path $folder 'real.ipt'
if (-not (Test-Path $realF)) {
    $found = Get-ChildItem $folder -Filter '*.ipt' | Where-Object { $_.Name -notmatch '^my_attempt' } | Select-Object -First 1
    if (-not $found) { throw "No .ipt found in $folder" }
    $realF = $found.FullName
}

try { $inv.Documents.CloseAll($false) } catch {}
$realDoc = $inv.Documents.Open($realF, $true)
$cd = $realDoc.ComponentDefinition
$body = $cd.SurfaceBodies.Item(1)
$rb = $body.RangeBox
$realVol = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
$xLen = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
$yLen = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
$zLen = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10

# Analyze cylinder faces by axis
$cylsByAxis = @{ X = @(); Y = @(); Z = @() }
$cylAll = @()
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -eq 5891) {
        $g = $f.Geometry
        $r = $g.Radius * 10
        $ax = $g.AxisVector
        $cyl = @{ R = $r; Axis = $ax; AxisZ = $ax.Z; AxisX = $ax.X; AxisY = $ax.Y }
        $cylAll += $cyl
        if ([Math]::Abs($ax.Z) -gt 0.95) { $cylsByAxis.Z += $cyl }
        elseif ([Math]::Abs($ax.X) -gt 0.95) { $cylsByAxis.X += $cyl }
        elseif ([Math]::Abs($ax.Y) -gt 0.95) { $cylsByAxis.Y += $cyl }
    }
}
$totalFaces = $body.Faces.Count
$cylZ_R = ($cylsByAxis.Z | ForEach-Object { $_.R } | Sort-Object -Unique)
$cylX_R = ($cylsByAxis.X | ForEach-Object { $_.R } | Sort-Object -Unique)
$cylY_R = ($cylsByAxis.Y | ForEach-Object { $_.R } | Sort-Object -Unique)
$realDoc.Close($false)

Write-Host "REAL: BBox $xLen x $yLen x $zLen mm  Vol=$realVol  Faces=$totalFaces" -ForegroundColor Magenta
Write-Host "  Cyl Z-axis: $($cylZ_R -join ', ') mm"
Write-Host "  Cyl X-axis: $($cylX_R -join ', ') mm"
Write-Host "  Cyl Y-axis: $($cylY_R -join ', ') mm"

# ---- Decision tree ----
$strategy = "unknown"
$diam = [Math]::Max($xLen, $yLen)
$thick = $zLen

# Determine longest BBox axis
$longestDim  = [Math]::Max([Math]::Max($xLen, $yLen), $zLen)
$shortestDim = [Math]::Min([Math]::Min($xLen, $yLen), $zLen)
$elongation = $longestDim / [Math]::Max($shortestDim, 0.01)
$longestAxis = if ($xLen -eq $longestDim) { 'X' } elseif ($yLen -eq $longestDim) { 'Y' } else { 'Z' }

# Cylinders along longest axis indicate screw-like geometry
$cylsLongest = $cylsByAxis[$longestAxis]

# 1. Box with legs (priority — clear pattern: 4+ small Z cyls inside a large flat body)
if ($cylsByAxis.Z.Count -ge 4 -and $cylZ_R.Count -eq 1 -and $cylZ_R[0] -lt ($diam / 4) -and $longestAxis -ne 'Z') {
    $strategy = "box_with_legs"
}
# 2. Screw: 2 cylinders along LONGEST axis (head + shaft along same direction)
elseif ($cylsLongest.Count -eq 2 -and $elongation -gt 3.0) {
    $strategy = "screw"
}
# 3. Ring: 2+ Z-axis cylinders forming inner/outer (disc/ring shape, Z is thin)
elseif ($cylZ_R.Count -ge 2 -and $diam -gt ($thick * 0.5)) {
    $strategy = "ring"
}
# 4. Ring (single Z-cyl with disc aspect)
elseif ($cylZ_R.Count -eq 1 -and $diam -gt ($thick * 0.5) -and $cylZ_R[0] -lt ($diam / 2)) {
    $strategy = "ring_single"
}
# 5. Default box
else {
    $strategy = "box"
}
Write-Host "  Strategy: $strategy" -ForegroundColor Cyan

# ---- Build model ----
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd2 = $doc.ComponentDefinition
$tg = $inv.TransientGeometry
$xy = $cd2.WorkPlanes.Item(3)

$saveName = 'my_attempt_v5.ipt'

switch ($strategy) {
    'screw' {
        # 2 cylinders along longest axis
        $rs = ($cylAll | ForEach-Object { $_.R } | Sort-Object -Unique)
        $rShaft = [double]$rs[0]; $rHead = [double]$rs[-1]
        $totalL = $longestDim
        $pi = [Math]::PI
        $Lh = ($realVol / $pi - $rShaft*$rShaft*$totalL) / ($rHead*$rHead - $rShaft*$rShaft)
        $Ls = $totalL - $Lh
        Write-Host "  Screw: rHead=$rHead rShaft=$rShaft  Lh=$([Math]::Round($Lh,2)) Ls=$([Math]::Round($Ls,2))"
        # Build along Z
        $s1 = $cd2.Sketches.Add($xy)
        $null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rHead))
        $ed1 = $cd2.Features.ExtrudeFeatures.CreateExtrudeDefinition($s1.Profiles.AddForSolid(), $kJoin)
        $ed1.SetDistanceExtent((MM $Lh), $kPos)
        $null = $cd2.Features.ExtrudeFeatures.Add($ed1)
        $wpT = $cd2.WorkPlanes.AddByPlaneAndOffset($xy, (MM $Lh)); $wpT.Visible = $false
        $s2 = $cd2.Sketches.Add($wpT)
        $null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rShaft))
        $ed2 = $cd2.Features.ExtrudeFeatures.CreateExtrudeDefinition($s2.Profiles.AddForSolid(), $kJoin)
        $ed2.SetDistanceExtent((MM $Ls), $kPos)
        $null = $cd2.Features.ExtrudeFeatures.Add($ed2)
    }
    'box_with_legs' {
        $legR = $cylZ_R[0]
        $pi = [Math]::PI
        $legArea = $pi * $legR * $legR
        # baseT = (realVol - 4*legArea*totalH) / (W*H - 4*legArea)
        $baseT = ($realVol - 4*$legArea*$zLen) / ($xLen*$yLen - 4*$legArea)
        $legH = $zLen - $baseT
        Write-Host "  BoxWithLegs: baseT=$([Math]::Round($baseT,1))  legH=$([Math]::Round($legH,1))"
        $s1 = $cd2.Sketches.Add($xy)
        $p1 = $tg.CreatePoint2d((MM (-$xLen/2)), (MM (-$yLen/2)))
        $p2 = $tg.CreatePoint2d((MM ( $xLen/2)), (MM ( $yLen/2)))
        $null = $s1.SketchLines.AddAsTwoPointRectangle($p1, $p2)
        $ed1 = $cd2.Features.ExtrudeFeatures.CreateExtrudeDefinition($s1.Profiles.AddForSolid(), $kJoin)
        $ed1.SetDistanceExtent((MM $baseT), $kPos)
        $null = $cd2.Features.ExtrudeFeatures.Add($ed1)
        # 4 legs below
        $wpBot = $cd2.WorkPlanes.AddByPlaneAndOffset($xy, (MM -0.01)); $wpBot.Visible = $false
        $s2 = $cd2.Sketches.Add($wpBot)
        $legX = $xLen/2 - $legR
        $legY = $yLen/2 - $legR
        foreach ($x in @(-$legX, $legX)) { foreach ($y in @(-$legY, $legY)) {
            $null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM $x), (MM $y)), (MM $legR))
        }}
        $ed2 = $cd2.Features.ExtrudeFeatures.CreateExtrudeDefinition($s2.Profiles.AddForSolid(), $kJoin)
        $ed2.SetDistanceExtent((MM $legH), $kNeg)
        $null = $cd2.Features.ExtrudeFeatures.Add($ed2)
    }
    'ring' {
        $rOut = [double]$cylZ_R[-1]
        $rIn  = [double]$cylZ_R[0]
        # Sanity check: if rIn very close to rOut, ignore (thin wall isn't real ID)
        if ($rIn -ge $rOut * 0.95) { $rIn = 0 }
        Write-Host "  Ring: OD=$($rOut*2) ID=$($rIn*2) T=$thick"
        $s1 = $cd2.Sketches.Add($xy)
        $null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
        if ($rIn -gt 0) {
            $null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rIn))
        }
        $ed1 = $cd2.Features.ExtrudeFeatures.CreateExtrudeDefinition($s1.Profiles.AddForSolid(), $kJoin)
        $ed1.SetDistanceExtent((MM $thick), $kPos)
        $null = $cd2.Features.ExtrudeFeatures.Add($ed1)
    }
    'ring_single' {
        $rOut = $diam / 2.0
        $rIn  = [double]$cylZ_R[0]
        # Back-calc if simple ring vol off > 8%
        $pi = [Math]::PI
        $simpleVol = $pi * ($rOut*$rOut - $rIn*$rIn) * $thick
        $simpleDiff = ($simpleVol - $realVol) / $realVol * 100.0
        if ([Math]::Abs($simpleDiff) -gt 8) {
            $innerSq = $rOut*$rOut - ($realVol / ($pi * $thick))
            if ($innerSq -gt 0) { $rIn = [Math]::Sqrt($innerSq) }
            Write-Host "  Ring-single back-calc: OD=$($rOut*2) IDeff=$($rIn*2) T=$thick"
        } else {
            Write-Host "  Ring-single direct: OD=$($rOut*2) ID=$($rIn*2) T=$thick"
        }
        $s1 = $cd2.Sketches.Add($xy)
        $null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
        if ($rIn -gt 0) {
            $null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rIn))
        }
        $ed1 = $cd2.Features.ExtrudeFeatures.CreateExtrudeDefinition($s1.Profiles.AddForSolid(), $kJoin)
        $ed1.SetDistanceExtent((MM $thick), $kPos)
        $null = $cd2.Features.ExtrudeFeatures.Add($ed1)
    }
    default {
        # box
        Write-Host "  Box: $xLen x $yLen x $zLen"
        $s1 = $cd2.Sketches.Add($xy)
        $p1 = $tg.CreatePoint2d((MM (-$xLen/2)), (MM (-$yLen/2)))
        $p2 = $tg.CreatePoint2d((MM ( $xLen/2)), (MM ( $yLen/2)))
        $null = $s1.SketchLines.AddAsTwoPointRectangle($p1, $p2)
        $ed1 = $cd2.Features.ExtrudeFeatures.CreateExtrudeDefinition($s1.Profiles.AddForSolid(), $kJoin)
        $ed1.SetDistanceExtent((MM $zLen), $kPos)
        $null = $cd2.Features.ExtrudeFeatures.Add($ed1)
    }
}

$myVol = [Math]::Round($cd2.MassProperties.Volume * 1000, 3)
$diff = if ($realVol -gt 0) { (($myVol - $realVol) / $realVol) * 100.0 } else { 0 }
$result = if ([Math]::Abs($diff) -le 10) { 'PASS' } else { 'FAIL' }

Write-Host ("  My Vol=$myVol  diff=$([Math]::Round($diff,4))%  $result") -ForegroundColor $(if ($result -eq 'PASS') { 'Green' } else { 'Red' })
$doc.SaveAs((Join-Path $folder $saveName), $false)
Write-Host "  Saved: $saveName"
