param([string]$folder = $PSScriptRoot)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

function Start-NagWatcher([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class BoxNag {
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
            [BoxNag]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][BoxNag]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][BoxNag]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [BoxNag]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][BoxNag]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
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
$nagJob = Start-NagWatcher $invPid

$realF = Join-Path $folder 'real.ipt'
try { $inv.Documents.CloseAll($false) } catch { }
$realDoc = $inv.Documents.Open($realF, $true)
$rcd = $realDoc.ComponentDefinition
$rbd = $rcd.SurfaceBodies.Item(1)
$rb = $rbd.RangeBox
$realVol = [Math]::Round($rcd.MassProperties.Volume * 1000, 3)
$x = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 4)
$y = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 4)
$z = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 4)

$surfaceCounts = @{}
$cylCount = 0
foreach ($f in $rbd.Faces) {
    $key = [string]$f.SurfaceType
    if (-not $surfaceCounts.ContainsKey($key)) { $surfaceCounts[$key] = 0 }
    $surfaceCounts[$key]++
    if ($f.SurfaceType -eq 5891) { $cylCount++ }
}
$realDoc.Close($false)

Write-Host ("REAL box candidate: {0} x {1} x {2} mm | Vol {3} | CylFaces {4}" -f $x, $y, $z, $realVol, $cylCount) -ForegroundColor Magenta
if ($cylCount -ne 0 -or $surfaceCounts['5890'] -ne 6) {
    Write-Host "WARNING: real.ipt is not a pure six-plane box; continuing as bbox template for learning." -ForegroundColor Yellow
}

$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition
$tg = $inv.TransientGeometry
$xy = $cd.WorkPlanes.Item(3)

$s = $cd.Sketches.Add($xy)
$p1 = $tg.CreatePoint2d((MM (-$x / 2)), (MM (-$y / 2)))
$p2 = $tg.CreatePoint2d((MM ($x / 2)), (MM ($y / 2)))
$null = $s.SketchLines.AddAsTwoPointRectangle($p1, $p2)
$profile = $s.Profiles.AddForSolid()
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($profile, $kJoin)
$ed.SetDistanceExtent((MM $z), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed)

$body = $cd.SurfaceBodies.Item(1)
$mp = $cd.MassProperties
$outRb = $body.RangeBox
$outX = [Math]::Round(($outRb.MaxPoint.X - $outRb.MinPoint.X) * 10, 3)
$outY = [Math]::Round(($outRb.MaxPoint.Y - $outRb.MinPoint.Y) * 10, 3)
$outZ = [Math]::Round(($outRb.MaxPoint.Z - $outRb.MinPoint.Z) * 10, 3)
$outVol = [Math]::Round($mp.Volume * 1000, 3)
$diffPct = (($outVol - $realVol) / $realVol) * 100
Write-Host ("My: BBox {0} x {1} x {2} | Vol {3} | diff {4:F4}%" -f $outX, $outY, $outZ, $outVol, $diffPct) -ForegroundColor Green

$doc.SaveAs((Join-Path $folder 'my_attempt_box_v1.ipt'), $false)
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
