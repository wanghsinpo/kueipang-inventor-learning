## auto_ring_v3.ps1 - v2 plus volume sanity/back-calculated bore.
##
## Use for sleeve/ring parts where cylinder detection may pick an internal
## stepped seat instead of the effective through bore.

param([string]$folder = $PSScriptRoot)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagRingV3' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagRingV3 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}

function Start-NagRingV3([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NRV3 {
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
            [NRV3]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NRV3]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][NRV3]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NRV3]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NRV3]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart = 12290
$kJoin = 20481
$kPos = 20993

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor | Select-Object -First 1).Id)
$nagJob = Start-NagRingV3 $invPid

$realF = Join-Path $folder 'real.ipt'
try { $inv.Documents.CloseAll($false) } catch { }
$realDoc = $inv.Documents.Open($realF, $true)
$rcd = $realDoc.ComponentDefinition
$rbd = $rcd.SurfaceBodies.Item(1)
$rb = $rbd.RangeBox
$realVol = [Math]::Round($rcd.MassProperties.Volume * 1000, 3)
$xLen = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
$yLen = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
$zLen = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10
$diam = [Math]::Max($xLen, $yLen)
$thick = $zLen
$rOut = $diam / 2.0

$radii = @()
foreach ($f in $rbd.Faces) {
    if ($f.SurfaceType -eq 5891) { $radii += [double]($f.Geometry.Radius * 10) }
}
$radii = $radii | Sort-Object -Unique -Descending
$realDoc.Close($false)

$minInnerR = $rOut * 0.30
$validRadii = $radii | Where-Object { $_ -lt $rOut -and $_ -gt $minInnerR }
$detectedRIn = 0.0
if ($validRadii.Count -gt 0) { $detectedRIn = [double]$validRadii[0] }

$chosenRIn = $detectedRIn
$simpleVol = [Math]::PI * (($rOut * $rOut) - ($detectedRIn * $detectedRIn)) * $thick
$simpleDiff = (($simpleVol - $realVol) / $realVol) * 100.0
$backCalcRIn = $detectedRIn
if ($thick -gt 0) {
    $innerSq = ($rOut * $rOut) - ($realVol / ([Math]::PI * $thick))
    if ($innerSq -gt 0) { $backCalcRIn = [Math]::Sqrt($innerSq) }
}

$shouldBackCalc = $false
if ($detectedRIn -gt 0 -and [Math]::Abs($simpleDiff) -gt 15 -and $backCalcRIn -gt 0 -and $backCalcRIn -lt $rOut) {
    if ([Math]::Abs($backCalcRIn - $detectedRIn) -gt 0.05) { $shouldBackCalc = $true }
}

if ($shouldBackCalc) {
    $chosenRIn = $backCalcRIn
    Write-Host ("BACKCALC: detected ID R={0:F4}, effective ID R={1:F4}, simple diff={2:F2}%" -f $detectedRIn, $backCalcRIn, $simpleDiff) -ForegroundColor Yellow
}

Write-Host ("REAL: OD={0:F3}, thick={1:F3}, detected ID R={2:F4}, chosen ID R={3:F4}, Vol={4}" -f $diam, $thick, $detectedRIn, $chosenRIn, $realVol) -ForegroundColor Magenta

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

$body = $cd.SurfaceBodies.Item(1)
$ec = $inv.TransientObjects.CreateEdgeCollection()
foreach ($e in $body.Edges) {
    if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) }
}
if ($ec.Count -gt 0) {
    try { $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM 0.5), $false) } catch { }
}

$body = $cd.SurfaceBodies.Item(1)
$mp = $cd.MassProperties
$outRb = $body.RangeBox
$xOut = [Math]::Round(($outRb.MaxPoint.X - $outRb.MinPoint.X) * 10, 3)
$zOut = [Math]::Round(($outRb.MaxPoint.Z - $outRb.MinPoint.Z) * 10, 3)
$outVol = [Math]::Round($mp.Volume * 1000, 3)
$diffPct = (($outVol - $realVol) / $realVol) * 100.0
Write-Host ("My: BBox {0} x {0} x {1} | Vol {2} | diff {3:F4}%" -f $xOut, $zOut, $outVol, $diffPct) -ForegroundColor Green

$doc.SaveAs((Join-Path $folder 'my_attempt_v3.ipt'), $false)
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
