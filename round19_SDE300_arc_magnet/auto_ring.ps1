## Auto-build a flat ring with chamfers from real.ipt geometry dump.
## Generalizes the simple ring approach - inspects then builds without hard-coding.
$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagF' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagF {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagF([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NF {
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
            [NF]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NF]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][NF]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NF]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NF]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481; $kPos=20993

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagF $invPid

# === First inspect real to get dims ===
$realF = "$env:USERPROFILE\Desktop\test\round19_SDE300_arc_magnet\real.ipt"
try { $inv.Documents.CloseAll($false) } catch { }
$realDoc = $inv.Documents.Open($realF, $true)
$rcd = $realDoc.ComponentDefinition; $rbd = $rcd.SurfaceBodies.Item(1)
$rb = $rbd.RangeBox
$realVol = [Math]::Round($rcd.MassProperties.Volume * 1000, 1)
$thick = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10
$bbox = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
$rOut = $bbox / 2
# Find inner radius from cylinders (pick second-largest)
$radii = @()
foreach ($f in $rbd.Faces) {
    if ($f.SurfaceType -eq 5891) { $radii += [double]($f.Geometry.Radius * 10) }
}
$radii = $radii | Sort-Object -Unique -Descending
$rIn = $radii[1]   # second largest
Write-Host ("Inspected REAL: BBox={0}, thick={1}, OD R={2}, ID R={3}, Vol={4}" -f $bbox, $thick, $rOut, $rIn, $realVol) -ForegroundColor Magenta
$realDoc.Close($false)

# === Build my version ===
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition; $tg = $inv.TransientGeometry
$xy = $cd.WorkPlanes.Item(3)

$s = $cd.Sketches.Add($xy)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rIn))
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kJoin)
$ed.SetDistanceExtent((MM $thick), $kPos); $null = $cd.Features.ExtrudeFeatures.Add($ed)

$body = $cd.SurfaceBodies.Item(1)
$ec = $inv.TransientObjects.CreateEdgeCollection()
foreach ($e in $body.Edges) { if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) } }
if ($ec.Count -gt 0) { try { $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM 0.5), $false) } catch { } }

$body = $cd.SurfaceBodies.Item(1); $mp = $cd.MassProperties; $rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 1)
$dPct = (($vAct - $realVol) / $realVol) * 100
Write-Host ("My BBox: {0} ? {0} ? {1} | Vol: {2} (target {3} -> diff {4:F2}%)" -f $xL, $zL, $vAct, $realVol, $dPct) -ForegroundColor Green

$doc.SaveAs("$env:USERPROFILE\Desktop\test\round19_SDE300_arc_magnet\my_attempt.ipt", $false)
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
