## Round 4: EV-L200-BP Flinger — same family as Round 1, different size.
## Test: did Round 1 lessons stick?

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagCloser5' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagCloser5 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-Nag5([uint32]$invPid) {
    return Start-Job -ScriptBlock {
        param($targetPid)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class N5 {
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
            [N5]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][N5]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0; [void][N5]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $targetPid -and [N5]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][N5]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart = 12290; $kJoin = 20481

# Sanity (corrected v2): disc Ø62 × 4.5 with Ø52×2 counterbore on left face,
# bore Ø35.1 through, hub Ø43 × 11 with same Ø35.1 bore.
# x=0..2: outer Ø62, inner Ø52 → π(31²-26²)×2 = 1790
# x=2..4.5: outer Ø62, inner Ø35.1 → π(31²-17.55²)×2.5 = 5130
# x=4.5..15.5: outer Ø43, inner Ø35.1 → π(21.5²-17.55²)×11 = 5325
$V_est = ([Math]::PI*(31*31-26*26)*4) + ([Math]::PI*(31*31-17.55*17.55)*0.5) + ([Math]::PI*(21.5*21.5-17.55*17.55)*11)
Write-Host ("Sanity vol_est (top-hat v2) = {0:N0} mm^3 (target 9,596)" -f $V_est) -ForegroundColor Magenta

# Connect
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
} catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2
}
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-Nag5 $invPid
try { $inv.Documents.CloseAll($false) } catch { }

$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition
$tg = $inv.TransientGeometry

$xy = $cd.WorkPlanes.Item(3)
$s1 = $cd.Sketches.Add($xy)

# CORRECTED v2: top-hat with counterbore Ø52 only at left face, depth 2.
# Bore Ø35.1 is the THROUGH bore; Ø52 is just a shallow counterbore on disc face.
# This avoids the self-intersection I had with full Ø52 through-bore (hub OD < disc inner).
$pts = @(
    @(0.0,    26.0),    # 0: counterbore opening at left face (Ø52)
    @(0.0,    31.0),    # 1: disc OD at left face (Ø62)
    @(4.5,    31.0),    # 2: disc OD at right (hub-side) face
    @(4.5,    21.5),    # 3: step down to hub OD (Ø43)
    @(15.5,   21.5),    # 4: hub end OD
    @(15.5,   17.55),   # 5: hub end inner (Ø35.1 bore)
    @(4.0,    17.55),   # 6: bore at counterbore floor (deeper c'bore: depth 4)
    @(4.0,    26.0)     # 7: counterbore step
)
$sketchPts = @()
foreach ($pt in $pts) {
    $p = $tg.CreatePoint2d((MM $pt[0]), (MM $pt[1]))
    $sketchPts += $s1.SketchPoints.Add($p, $false)
}
for ($i = 0; $i -lt $sketchPts.Count; $i++) {
    $a = $sketchPts[$i]; $b = $sketchPts[($i + 1) % $sketchPts.Count]
    $null = $s1.SketchLines.AddByTwoPoints($a, $b)
}
Write-Host ("Profile lines: {0}" -f $s1.SketchLines.Count) -ForegroundColor DarkGray

$xAxis = $cd.WorkAxes.Item(1)
$prof = $s1.Profiles.AddForSolid()
$null = $cd.Features.RevolveFeatures.AddFull($prof, $xAxis, $kJoin)

$out = "$env:USERPROFILE\Desktop\test\round4_BP_Flinger\my_attempt.ipt"
$doc.SaveAs($out, $false)

$body = $cd.SurfaceBodies.Item(1); $mp = $cd.MassProperties; $rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 0)
Write-Host ("My BBox: {0} x {1} x {2}" -f $xL, $yL, $zL) -ForegroundColor Green
Write-Host ("My Vol:  {0} mm^3 (sanity {1:N0})" -f $vAct, [Math]::Round($V_est,0)) -ForegroundColor Green

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
