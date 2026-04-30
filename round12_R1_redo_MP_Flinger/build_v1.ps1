## R12 — Redo Round 1 (MP Flinger) with top-hat understanding from R4 lesson.
## From geometry dump:
##   BBox 49×49×15.5, Vol 6,549
##   Outer step: Ø49(2) → Ø43(3.5) → Ø39(3.5) → Ø28(4.5)
##   Bore: Ø20.05 (R=10.03) main, with Ø24 (R=12) widening at z=10.5-12.5
## SIMPLIFIED: disc (Ø49)+body (Ø39)+hub (Ø28), bore Ø20.05 thru.

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagG' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagG {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagG([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NG {
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
            [NG]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NG]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][NG]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NG]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NG]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagG $invPid
try { $inv.Documents.CloseAll($false) } catch { }

$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition; $tg = $inv.TransientGeometry
$xy = $cd.WorkPlanes.Item(3)
$s = $cd.Sketches.Add($xy)

# Stepped revolved profile (X axial, Y radial). Match real geometry steps.
# z=0..2: Ø49 ring → R=24.5
# z=2..5.5: Ø43 → R=21.5
# z=5.5..9: Ø39 → R=19.5
# z=9..11: transition (assume same Ø39 for simplicity)
# z=11..15.5: Ø28 hub → R=14
# Bore Ø20.05 → R=10.03 throughout
$pts = @(
    @(0,    10.03),    # bore at z=0
    @(0,    24.5),     # outer at z=0 (Ø49)
    @(2,    24.5),     # Ø49 top
    @(2,    21.5),     # step Ø49→Ø43
    @(5.5,  21.5),     # Ø43 end
    @(5.5,  19.5),     # step Ø43→Ø39
    @(11,   19.5),     # Ø39 end
    @(11,   14),       # step Ø39→Ø28
    @(15.5, 14),       # hub end
    @(15.5, 10.03)     # bore at z=15.5
)
$sketchPts = @()
foreach ($pt in $pts) {
    $p = $tg.CreatePoint2d((MM $pt[0]), (MM $pt[1]))
    $sketchPts += $s.SketchPoints.Add($p, $false)
}
for ($i = 0; $i -lt $sketchPts.Count; $i++) {
    $a = $sketchPts[$i]; $b = $sketchPts[($i + 1) % $sketchPts.Count]
    $null = $s.SketchLines.AddByTwoPoints($a, $b)
}

$xAxis = $cd.WorkAxes.Item(1)
$null = $cd.Features.RevolveFeatures.AddFull($s.Profiles.AddForSolid(), $xAxis, $kJoin)

$body = $cd.SurfaceBodies.Item(1); $mp = $cd.MassProperties; $rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 1)
Write-Host ("BBox: {0} × {1} × {2}  (target 49 × 49 × 15.5)" -f $xL,$yL,$zL) -ForegroundColor Green
Write-Host ("Vol:  {0} mm³  (target 6,548.8 → diff {1:F2}%)" -f $vAct, ((($vAct - 6548.8)/6548.8)*100)) -ForegroundColor Green

$doc.SaveAs("$env:USERPROFILE\Desktop\test\round12_R1_redo_MP_Flinger\my_attempt.ipt", $false)
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
