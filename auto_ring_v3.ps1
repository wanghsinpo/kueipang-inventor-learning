## auto_ring_v3.ps1 — adds bolt-hole subtraction.
## Reads real.ipt → Outer Ø, Inner Ø, bolt-hole radii + positions → builds matching ring with holes.
##
## Input: -folder <path-to-round-folder> (must contain real.ipt)
## Output: <folder>/my_attempt.ipt + console diff

param([string]$folder)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not $folder) { Write-Error "Usage: auto_ring_v3.ps1 -folder <path>"; exit 1 }
if (-not (Test-Path "$folder\real.ipt")) { Write-Error "real.ipt not in $folder"; exit 1 }

if (-not ('Nag10' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class Nag10 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-Nag10([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class N10 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
        $stop = (Get-Date).AddMinutes(5)
        while ((Get-Date) -lt $stop) {
            $hits = [System.Collections.Generic.List[IntPtr]]::new()
            [N10]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][N10]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][N10]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [N10]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][N10]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481; $kCut=20482; $kPos=20993

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-Nag10 $invPid
try { $inv.Documents.CloseAll($false) } catch { }

# === Inspect real ===
$realDoc = $inv.Documents.Open("$folder\real.ipt", $true)
$rcd = $realDoc.ComponentDefinition; $rbd = $rcd.SurfaceBodies.Item(1)
$rb = $rbd.RangeBox
$realVol = [Math]::Round($rcd.MassProperties.Volume * 1000, 1)
$thick = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 3)
$bbox  = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 3)

# Collect all cylindrical faces with axis Z (vertical)
$cyls = @()
foreach ($f in $rbd.Faces) {
    if ($f.SurfaceType -ne 5891) { continue }
    if ([Math]::Abs([double]$f.Geometry.AxisVector.Z) -lt 0.99) { continue }
    $cyls += [PSCustomObject]@{
        R = [Math]::Round($f.Geometry.Radius * 10, 3)
        BX = [Math]::Round($f.Geometry.BasePoint.X * 10, 3)
        BY = [Math]::Round($f.Geometry.BasePoint.Y * 10, 3)
    }
}

# Identify outer / inner / bolt-hole radii
$radiiSorted = $cyls | Group-Object R | ForEach-Object {
    [PSCustomObject]@{R=$_.Name; Count=$_.Count; Centers=$_.Group}
} | Sort-Object {[double]$_.R} -Descending

$rOut = [double]$radiiSorted[0].R
$rIn = $null
foreach ($g in $radiiSorted) {
    if ([double]$g.R -lt ($rOut * 0.95) -and [double]$g.R -gt ($rOut * 0.30)) {
        $rIn = [double]$g.R
        break
    }
}
if ($null -eq $rIn) { $rIn = [double]$radiiSorted[1].R }

# Bolt holes: small radii (< 30% of OD) that have nonzero center offset (not at origin)
$boltHoles = @()
foreach ($g in $radiiSorted) {
    $r = [double]$g.R
    if ($r -ge ($rOut * 0.30)) { continue }
    if ($r -lt 0.5) { continue }   # ignore tiny chamfer artifacts
    foreach ($c in $g.Centers) {
        $dist = [Math]::Sqrt(([double]$c.BX)*([double]$c.BX) + ([double]$c.BY)*([double]$c.BY))
        if ($dist -gt 1) {  # not at origin → likely a bolt hole
            $boltHoles += [PSCustomObject]@{R = $r; X = [double]$c.BX; Y = [double]$c.BY; PCD = $dist}
        }
    }
}
# Deduplicate (sometimes same hole appears twice as top + bottom faces of cylinder)
$uniqueHoles = @()
foreach ($h in $boltHoles) {
    $dup = $false
    foreach ($u in $uniqueHoles) {
        if ([Math]::Abs($u.X - $h.X) -lt 0.5 -and [Math]::Abs($u.Y - $h.Y) -lt 0.5 -and [Math]::Abs($u.R - $h.R) -lt 0.1) { $dup = $true; break }
    }
    if (-not $dup) { $uniqueHoles += $h }
}

Write-Host ("REAL: BBox={0}, thick={1}, OD R={2}, ID R={3}, Vol={4}" -f $bbox, $thick, $rOut, $rIn, $realVol) -ForegroundColor Magenta
Write-Host ("  Bolt holes detected: {0}" -f $uniqueHoles.Count) -ForegroundColor Magenta
foreach ($h in $uniqueHoles) {
    Write-Host ("    R={0:F2} at ({1:F2},{2:F2}) PCD={3:F2}" -f $h.R, $h.X, $h.Y, $h.PCD) -ForegroundColor DarkGray
}
$realDoc.Close($false)

# === Build my version ===
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition; $tg = $inv.TransientGeometry
$xy = $cd.WorkPlanes.Item(3)

# Step 1: Pad ring
$s = $cd.Sketches.Add($xy)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rIn))
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kJoin)
$ed.SetDistanceExtent((MM $thick), $kPos); $null = $cd.Features.ExtrudeFeatures.Add($ed)

# Step 2: Cut bolt holes
if ($uniqueHoles.Count -gt 0) {
    $body = $cd.SurfaceBodies.Item(1)
    # Find top face for sketch
    $topFace = $null; $maxA = 0
    foreach ($f in $body.Faces) {
        if ($f.SurfaceType -ne 5890) { continue }
        $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
        if ([Math]::Abs($n.Z) -gt 0.5 -and [Math]::Abs($r.Z - (MM $thick)) -lt 0.01) {
            if ($f.Evaluator.Area -gt $maxA) { $maxA = $f.Evaluator.Area; $topFace = $f }
        }
    }
    if ($topFace) {
        $sBolt = $cd.Sketches.Add($topFace)
        foreach ($h in $uniqueHoles) {
            $null = $sBolt.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM $h.X), (MM $h.Y)), (MM $h.R))
        }
        $edB = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($sBolt.Profiles.AddForSolid(), $kCut)
        $edB.SetDistanceExtent((MM ($thick + 1)), 20994)  # neg direction (cut down)
        $null = $cd.Features.ExtrudeFeatures.Add($edB)
    }
}

# Chamfers on circular edges
$body = $cd.SurfaceBodies.Item(1)
$ec = $inv.TransientObjects.CreateEdgeCollection()
foreach ($e in $body.Edges) { if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) } }
if ($ec.Count -gt 0) { try { $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM 0.5), $false) } catch { } }

$body = $cd.SurfaceBodies.Item(1); $mp = $cd.MassProperties
$vAct = [Math]::Round($mp.Volume * 1000, 1)
$dPct = (($vAct - $realVol) / $realVol) * 100
$rb2 = $body.RangeBox
$xL = [Math]::Round(($rb2.MaxPoint.X - $rb2.MinPoint.X) * 10, 2)
$zL = [Math]::Round(($rb2.MaxPoint.Z - $rb2.MinPoint.Z) * 10, 2)
Write-Host ("My BBox: {0} x {0} x {1} | Vol: {2} | target {3} -> diff {4:F2}%" -f $xL, $zL, $vAct, $realVol, $dPct) -ForegroundColor Green

$doc.SaveAs("$folder\my_attempt.ipt", $false)
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
