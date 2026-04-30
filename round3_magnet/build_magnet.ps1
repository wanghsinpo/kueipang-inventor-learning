## Round 3: 58.4x17x5.2T-N52 magnet ring
## Lessons applied: BBox sanity, volume sanity, chamfers DONE not skipped, nag-watcher.

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagCloser4' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagCloser4 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagWatcher4([uint32]$invPid) {
    return Start-Job -ScriptBlock {
        param($targetPid)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class N4 {
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
            [N4]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][N4]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0; [void][N4]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $targetPid -and [N4]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][N4]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart = 12290
$kJoin = 20481
$kCut  = 20482
$kPos  = 20993

# ---- Dims ----
$D_OUT = 58.4
$D_IN  = 17.0
$THICK = 5.2
$CHAM  = 0.5

# ---- Sanity check ----
$rOut = $D_OUT / 2.0
$rIn  = $D_IN  / 2.0
$vEst = [Math]::PI * ($rOut*$rOut - $rIn*$rIn) * $THICK
Write-Host ("Sanity: vol_est = {0:N0} mm^3, BBox_est = {1} x {1} x {2}" -f $vEst, $D_OUT, $THICK) -ForegroundColor Magenta

# ---- Connect ----
Write-Host "Connecting Inventor..." -ForegroundColor Cyan
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
} catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application'))
    Start-Sleep 2
}
$inv.Visible = $true

$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagWatcher4 $invPid

try { $inv.Documents.CloseAll($false) } catch { }

Write-Host "New part..." -ForegroundColor Cyan
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition
$tg = $inv.TransientGeometry

# ---- Step 1: Ring outline + extrude ----
Write-Host "Step 1: Ring sketch (outer Ø$D_OUT, inner Ø$D_IN) + extrude ${THICK}mm..." -ForegroundColor Cyan
$xy = $cd.WorkPlanes.Item(3)
$s1 = $cd.Sketches.Add($xy)
$null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM ($D_OUT/2.0)))
$null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM ($D_IN/2.0)))
$prof1 = $s1.Profiles.AddForSolid()
$ed1 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof1, $kJoin)
$ed1.SetDistanceExtent((MM $THICK), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed1)

# ---- Step 2: Chamfer all 4 circular edges ----
Write-Host "Step 2: Chamfer 4 circular edges with C${CHAM}..." -ForegroundColor Cyan
$body = $cd.SurfaceBodies.Item(1)

# Build EdgeCollection of circular edges
$ec = $inv.TransientObjects.CreateEdgeCollection()
foreach ($edge in $body.Edges) {
    if ($edge.GeometryType -eq 38914) {  # kCircleCurve
        $null = $ec.Add($edge)
    }
}
Write-Host ("  Found {0} circular edges" -f $ec.Count) -ForegroundColor DarkGray
if ($ec.Count -gt 0) {
    $chDef = $cd.Features.ChamferFeatures.CreateChamferDefinition()
    $chDef.SetTwoDistancesChamfer($ec, (MM $CHAM), (MM $CHAM))
    try {
        $null = $cd.Features.ChamferFeatures.Add($chDef)
        Write-Host "  Chamfer added (TwoDistances)" -ForegroundColor Green
    } catch {
        # Fallback to simple distance chamfer
        $chDef2 = $cd.Features.ChamferFeatures.CreateChamferDefinition()
        $chDef2.SetEqualDistanceChamfer($ec, (MM $CHAM))
        $null = $cd.Features.ChamferFeatures.Add($chDef2)
        Write-Host "  Chamfer added (EqualDistance fallback)" -ForegroundColor Green
    }
}

# ---- Save ----
$out = "$env:USERPROFILE\Desktop\test\round3_magnet\my_attempt.ipt"
Write-Host "Saving to $out ..." -ForegroundColor Cyan
$doc.SaveAs($out, $false)

# Read back
$body = $cd.SurfaceBodies.Item(1)
$mp = $cd.MassProperties
$rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 1)

Write-Host ""
Write-Host ("My BBox: {0} x {1} x {2} mm" -f $xL, $yL, $zL) -ForegroundColor Green
Write-Host ("My Vol:  {0} mm^3 (sanity {1:N0})" -f $vAct, [Math]::Round($vEst,0)) -ForegroundColor Green

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
Write-Host "Done." -ForegroundColor Green
