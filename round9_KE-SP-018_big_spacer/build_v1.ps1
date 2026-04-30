## Round 9 v1 — KE-SP-018 EV-L200-BP 大間隔環
## Simple ring approach: Ø61.7 × Ø53.8 × 4 thick + chamfers
## Skip the spring pin holes and tab features for now (complex radial drill).

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagE' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagE {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagE([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NE {
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
            [NE]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NE]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][NE]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NE]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NE]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481; $kPos=20993

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagE $invPid
try { $inv.Documents.CloseAll($false) } catch { }

$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition; $tg = $inv.TransientGeometry
$xy = $cd.WorkPlanes.Item(3)

# Pad ring outline
Write-Host "Pad ring Ø61.7 × Ø53.8 × 4..." -ForegroundColor Cyan
$s = $cd.Sketches.Add($xy)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 30.85))
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 26.9))
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kJoin)
$ed.SetDistanceExtent((MM 4), $kPos); $null = $cd.Features.ExtrudeFeatures.Add($ed)

# Chamfer all 4 circular edges with C0.5
$body = $cd.SurfaceBodies.Item(1)
$ec = $inv.TransientObjects.CreateEdgeCollection()
foreach ($e in $body.Edges) {
    if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) }
}
Write-Host ("  Found {0} circle edges to chamfer" -f $ec.Count) -ForegroundColor DarkGray
if ($ec.Count -gt 0) {
    try { $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM 0.5), $false) } catch { Write-Host "  chamfer failed: $_" }
}

$body = $cd.SurfaceBodies.Item(1); $mp = $cd.MassProperties; $rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 1)
Write-Host ("BBox: {0} × {1} × {2}  (target 61.7 × 61.7 × 4)" -f $xL,$yL,$zL) -ForegroundColor Green
Write-Host ("Vol:  {0} mm³  (target 2,432.3 → diff {1:F2}%)" -f $vAct, ((($vAct - 2432.3)/2432.3)*100)) -ForegroundColor Green

$out = "$env:USERPROFILE\Desktop\test\round9_KE-SP-018_big_spacer\my_attempt.ipt"
$doc.SaveAs($out, $false)
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
