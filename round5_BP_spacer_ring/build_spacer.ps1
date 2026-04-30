## Round 5: EV-L200-BP-小間隔環
## Iso analysis: FLAT RING. No hub, no step, no chamfer (PDF doesn't note any).
## Plan: Sketch concentric Ø44.7 + Ø35.3 circles → extrude 4mm. Done.

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('Nag6' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class Nag6 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-Nag6([uint32]$invPid) {
    return Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class N6 {
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
            [N6]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][N6]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0; [void][N6]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [N6]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][N6]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart = 12290; $kJoin = 20481; $kPos = 20993

# ---- Dims (from PDF) ----
$D_OUT = 44.7
$D_IN  = 35.3
$THICK = 4.0

# ---- Sanity check ----
$rO = $D_OUT / 2.0
$rI = $D_IN / 2.0
$V_est = [Math]::PI * ($rO*$rO - $rI*$rI) * $THICK
Write-Host ("Sanity vol_est = {0:N0} mm^3, BBox_est = {1} x {1} x {2}" -f $V_est, $D_OUT, $THICK) -ForegroundColor Magenta

# ---- Connect ----
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true

$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-Nag6 $invPid

try { $inv.Documents.CloseAll($false) } catch { }

Write-Host "Creating part..." -ForegroundColor Cyan
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition
$tg = $inv.TransientGeometry

# ---- Sketch ring outline + extrude ----
Write-Host "Step 1: Ring (Ø$D_OUT outer, Ø$D_IN inner) + extrude ${THICK}mm..." -ForegroundColor Cyan
$xy = $cd.WorkPlanes.Item(3)
$s1 = $cd.Sketches.Add($xy)
$null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM ($D_OUT/2.0)))
$null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM ($D_IN/2.0)))
$prof = $s1.Profiles.AddForSolid()
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof, $kJoin)
$ed.SetDistanceExtent((MM $THICK), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed)

# ---- Read back, sanity check ----
$body = $cd.SurfaceBodies.Item(1)
$mp = $cd.MassProperties
$rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 2)

$bboxOK = ([Math]::Abs($xL - $D_OUT) -lt 0.1) -and ([Math]::Abs($yL - $D_OUT) -lt 0.1) -and ([Math]::Abs($zL - $THICK) -lt 0.1)
$volOK = ([Math]::Abs(($vAct - $V_est) / $V_est) -lt 0.01)

Write-Host ""
$bboxColor = if ($bboxOK) { 'Green' } else { 'Red' }
$volColor  = if ($volOK)  { 'Green' } else { 'Red' }
Write-Host ("BBox: {0} x {1} x {2} mm  (expect {3} x {3} x {4}) -> OK={5}" -f $xL,$yL,$zL,$D_OUT,$THICK,$bboxOK) -ForegroundColor $bboxColor
Write-Host ("Vol:  {0} mm^3  (estimate {1:N0}) -> OK={2}" -f $vAct,$V_est,$volOK) -ForegroundColor $volColor

if ($bboxOK -and $volOK) {
    $out = "$env:USERPROFILE\Desktop\test\round5_BP_spacer_ring\my_attempt.ipt"
    $doc.SaveAs($out, $false)
    Write-Host "Saved to $out" -ForegroundColor Green
} else {
    Write-Host "Sanity FAIL — NOT saving. Investigate." -ForegroundColor Red
}

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
