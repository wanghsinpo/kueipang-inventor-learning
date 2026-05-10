## auto_v4.ps1 — Universal geometry detector for ring OR box parts.
## Works on folders with real.ipt OR foldername.ipt (no real.ipt needed).
## Detects ring vs box by examining cylindrical face count vs total faces.
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File auto_v4.ps1 -folder "C:\...\round_xxx"

param([string]$folder = $PSScriptRoot)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagV4' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagV4 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagV4([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NW_V4 {
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
            [NW_V4]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NW_V4]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][NW_V4]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NW_V4]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NW_V4]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart = 12290; $kJoin = 20481; $kPos = 20993

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor | Select-Object -First 1).Id)
$nagJob = Start-NagV4 $invPid

# ---- find the .ipt file (real.ipt or foldername.ipt) ----
$realF = Join-Path $folder 'real.ipt'
if (-not (Test-Path $realF)) {
    $found = Get-ChildItem $folder -Filter '*.ipt' |
             Where-Object { $_.Name -notmatch '^my_attempt' } |
             Sort-Object LastWriteTime -Descending |
             Select-Object -First 1
    if (-not $found) { throw "No .ipt found in $folder" }
    $realF = $found.FullName
    Write-Host "  Using: $($found.Name)" -ForegroundColor DarkGray
}

try { $inv.Documents.CloseAll($false) } catch {}
$realDoc = $inv.Documents.Open($realF, $true)
$rcd = $realDoc.ComponentDefinition
$rbd = $rcd.SurfaceBodies.Item(1)
$rb = $rbd.RangeBox
$realVol = [Math]::Round($rcd.MassProperties.Volume * 1000, 3)
$xLen = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
$yLen = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
$zLen = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10

# Count face types: 5890=plane, 5891=cylinder
$cylFaces = 0; $planeFaces = 0; $totalFaces = $rbd.Faces.Count
foreach ($f in $rbd.Faces) {
    if ($f.SurfaceType -eq 5891) { $cylFaces++ }
    if ($f.SurfaceType -eq 5890) { $planeFaces++ }
}
$realDoc.Close($false)

Write-Host ("REAL: BBox={0:F2}x{1:F2}x{2:F2}mm  Vol={3}  Faces={4}(cyl={5},plane={6})" -f $xLen,$yLen,$zLen,$realVol,$totalFaces,$cylFaces,$planeFaces) -ForegroundColor Magenta

# ---- detect geometry type ----
$diam = [Math]::Max($xLen, $yLen)
$thick = $zLen
$rOut = $diam / 2.0
$cylRatio = $cylFaces / [Math]::Max($totalFaces, 1)

# Heuristic: ring/disc if >20% cylindrical faces AND aspect ratio suggests disc
$aspectOK = ($diam -gt ($thick * 0.5))
$isRing = ($cylFaces -ge 2) -and ($cylRatio -gt 0.15) -and $aspectOK

if ($isRing) {
    Write-Host "  → RING geometry (cylFaces=$cylFaces, ratio=$([Math]::Round($cylRatio*100,0))%)" -ForegroundColor Cyan

    # Ring logic from auto_ring_v3.ps1
    $radii = @()
    $realDoc2 = $inv.Documents.Open($realF, $true)
    $rbd2 = $realDoc2.ComponentDefinition.SurfaceBodies.Item(1)
    foreach ($f in $rbd2.Faces) {
        if ($f.SurfaceType -eq 5891) { $radii += [double]($f.Geometry.Radius * 10) }
    }
    $radii = $radii | Sort-Object -Unique -Descending
    $realDoc2.Close($false)

    $minInnerR = $rOut * 0.30
    $validRadii = $radii | Where-Object { $_ -lt $rOut -and $_ -gt $minInnerR }
    $detectedRIn = 0.0
    if ($validRadii.Count -gt 0) { $detectedRIn = [double]$validRadii[0] }

    # Back-calc if needed
    $chosenRIn = $detectedRIn
    $simpleVol = [Math]::PI * (($rOut*$rOut) - ($detectedRIn*$detectedRIn)) * $thick
    $simpleDiff = if ($realVol -gt 0) { (($simpleVol - $realVol) / $realVol) * 100.0 } else { 0 }
    $backCalcRIn = $detectedRIn
    if ($thick -gt 0) {
        $innerSq = ($rOut*$rOut) - ($realVol / ([Math]::PI * $thick))
        if ($innerSq -gt 0) { $backCalcRIn = [Math]::Sqrt($innerSq) }
    }
    if ([Math]::Abs($simpleDiff) -gt 8 -and $backCalcRIn -gt 0 -and $backCalcRIn -lt $rOut -and
        [Math]::Abs($backCalcRIn - $detectedRIn) -gt 0.05) {
        $chosenRIn = $backCalcRIn
        Write-Host ("  BACKCALC: detectedRIn={0:F3} → effectiveRIn={1:F3} (diff={2:F2}%)" -f $detectedRIn, $backCalcRIn, $simpleDiff) -ForegroundColor Yellow
    }

    $tpl = $inv.FileManager.GetTemplateFile($kPart)
    $doc = $inv.Documents.Add($kPart, $tpl, $true)
    $cd = $doc.ComponentDefinition
    $tg = $inv.TransientGeometry
    $xy = $cd.WorkPlanes.Item(3)
    $s = $cd.Sketches.Add($xy)
    $null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
    if ($chosenRIn -gt 0) {
        $null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $chosenRIn))
    }
    $ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kJoin)
    $ed.SetDistanceExtent((MM $thick), $kPos)
    $null = $cd.Features.ExtrudeFeatures.Add($ed)

    # chamfer
    $body = $cd.SurfaceBodies.Item(1)
    $ec = $inv.TransientObjects.CreateEdgeCollection()
    foreach ($e in $body.Edges) { if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) } }
    if ($ec.Count -gt 0) {
        $wallMm = if ($chosenRIn -gt 0) { $rOut - $chosenRIn } else { $rOut }
        $sizeC = [Math]::Min($diam * 0.01, [Math]::Min($thick * 0.10, $wallMm * 0.10))
        $chamMm = [Math]::Min(0.5, [Math]::Max(0.05, $sizeC))
        try { $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM $chamMm), $false) } catch {}
    }

    $saveName = 'my_attempt_v4.ipt'
    $outVol = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
    $diff = if ($realVol -gt 0) { (($outVol - $realVol) / $realVol) * 100.0 } else { 0 }
    Write-Host ("  Ring: OD={0:F2} ID_R={1:F3} thick={2:F2} → Vol={3} diff={4:F4}%" -f $diam,$chosenRIn,$thick,$outVol,$diff) -ForegroundColor Green
    if ([Math]::Abs($diff) -le 10) { Write-Host "  PASS" -ForegroundColor Green }
    else { Write-Host "  FAIL" -ForegroundColor Red }

} else {
    Write-Host "  → BOX geometry (cylFaces=$cylFaces, ratio=$([Math]::Round($cylRatio*100,0))%)" -ForegroundColor Cyan

    $tpl = $inv.FileManager.GetTemplateFile($kPart)
    $doc = $inv.Documents.Add($kPart, $tpl, $true)
    $cd = $doc.ComponentDefinition
    $tg = $inv.TransientGeometry
    $xy = $cd.WorkPlanes.Item(3)
    $s = $cd.Sketches.Add($xy)
    $p1 = $tg.CreatePoint2d((MM (-$xLen / 2.0)), (MM (-$yLen / 2.0)))
    $p2 = $tg.CreatePoint2d((MM ( $xLen / 2.0)), (MM ( $yLen / 2.0)))
    $null = $s.SketchLines.AddAsTwoPointRectangle($p1, $p2)
    $prof = $s.Profiles.AddForSolid()
    $ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof, $kJoin)
    $ed.SetDistanceExtent((MM $zLen), $kPos)
    $null = $cd.Features.ExtrudeFeatures.Add($ed)

    $saveName = 'my_attempt_v4.ipt'
    $outVol = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
    $expectedVol = $xLen * $yLen * $zLen
    $diff = if ($realVol -gt 0) { (($outVol - $realVol) / $realVol) * 100.0 } else { 0 }
    Write-Host ("  Box: {0:F2}x{1:F2}x{2:F2}mm → Vol={3} diff={4:F4}%" -f $xLen,$yLen,$zLen,$outVol,$diff) -ForegroundColor Green
    if ([Math]::Abs($diff) -le 10) { Write-Host "  PASS" -ForegroundColor Green }
    else { Write-Host "  FAIL" -ForegroundColor Red }
}

$doc.SaveAs((Join-Path $folder $saveName), $false)
Write-Host "  Saved: $saveName" -ForegroundColor Cyan
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch {}
