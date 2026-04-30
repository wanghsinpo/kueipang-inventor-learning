## Round 7 v1 — KE-BH-069 EV-L200-MP M側-左 (LEFT bearing seat, mirror of round 2)
## All R6 lessons applied:
##   1. Geometry dumped from real.ipt FIRST → exact dims
##   2. NW chord cut (same direction as right version)
##   3. 4 slots: 2 top (z=19→9, depth 10) + 2 bottom (z=0→3, depth 3)
##   4. Slots OUTSIDE cavity radius (R=26)
##   5. Don't cut through (slots stop short of each other)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagC' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagC {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagC([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NC {
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
            [NC]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NC]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][NC]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NC]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NC]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481; $kCut=20482; $kPos=20993; $kNeg=20994

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagC $invPid
try { $inv.Documents.CloseAll($false) } catch { }

function AddRect($s, $tg, $x1, $y1, $x2, $y2) {
    $p = @(
        $tg.CreatePoint2d((MM $x1), (MM $y1)),
        $tg.CreatePoint2d((MM $x2), (MM $y1)),
        $tg.CreatePoint2d((MM $x2), (MM $y2)),
        $tg.CreatePoint2d((MM $x1), (MM $y2))
    )
    $sp = @()
    foreach ($pt in $p) { $sp += $s.SketchPoints.Add($pt, $false) }
    for ($i = 0; $i -lt 4; $i++) {
        $null = $s.SketchLines.AddByTwoPoints($sp[$i], $sp[($i + 1) % 4])
    }
}
function FindZ($body, $zMm, $needPosNormal) {
    $best = $null; $bestArea = 0
    foreach ($f in $body.Faces) {
        if ($f.SurfaceType -ne 5890) { continue }
        $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
        if ([Math]::Abs($r.Z - (MM $zMm)) -lt 0.01 -and [Math]::Abs($n.Z) -gt 0.5) {
            if ($needPosNormal -and $n.Z -lt 0) { continue }
            if (-not $needPosNormal -and $n.Z -gt 0) { continue }
            $a = $f.Evaluator.Area
            if ($a -gt $bestArea) { $bestArea = $a; $best = $f }
        }
    }
    return $best
}

$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition; $tg = $inv.TransientGeometry
$xy = $cd.WorkPlanes.Item(3)

# Step 1: Pad Ø70 × 19
Write-Host "Step 1: Pad Ø70 × 19..." -ForegroundColor Cyan
$s = $cd.Sketches.Add($xy)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 35))
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kJoin)
$ed.SetDistanceExtent((MM 19), $kPos); $null = $cd.Features.ExtrudeFeatures.Add($ed)
$body = $cd.SurfaceBodies.Item(1)

# Step 2: Cut Ø52 cavity from top, depth 18 (almost through)
Write-Host "Step 2: Cut Ø52 cavity from top, depth 18..." -ForegroundColor Cyan
$tf = FindZ $body 19 $true
$s = $cd.Sketches.Add($tf)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 26))
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kCut)
$ed.SetDistanceExtent((MM 18), $kNeg); $null = $cd.Features.ExtrudeFeatures.Add($ed)

# Step 3: 2 M5 holes at (0, ±30.5)
Write-Host "Step 3: 2 M5 holes..." -ForegroundColor Cyan
$tf = FindZ $body 19 $true; $s = $cd.Sketches.Add($tf)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 0), (MM 30.5)), (MM 2.067))
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 0), (MM -30.5)), (MM 2.067))
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kCut)
$ed.SetDistanceExtent((MM 22), $kNeg); $null = $cd.Features.ExtrudeFeatures.Add($ed)

# Step 4: 2 Ø5 thru at (±30.5, 0)
Write-Host "Step 4: 2 Ø5 thru..." -ForegroundColor Cyan
$tf = FindZ $body 19 $true; $s = $cd.Sketches.Add($tf)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 30.5), (MM 0)), (MM 2.5))
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM -30.5), (MM 0)), (MM 2.5))
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kCut)
$ed.SetDistanceExtent((MM 22), $kNeg); $null = $cd.Features.ExtrudeFeatures.Add($ed)

# Step 5: 2 Ø7.9 c'bores depth 5.5
Write-Host "Step 5: 2 Ø7.9 c'bores..." -ForegroundColor Cyan
$tf = FindZ $body 19 $true; $s = $cd.Sketches.Add($tf)
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 30.5), (MM 0)), (MM 3.95))
$null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM -30.5), (MM 0)), (MM 3.95))
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kCut)
$ed.SetDistanceExtent((MM 5.5), $kNeg); $null = $cd.Features.ExtrudeFeatures.Add($ed)

# Step 6: NW chord cut (same direction as right, x+y < -45.16)
Write-Host "Step 6: NW chord cut..." -ForegroundColor Cyan
$tf = FindZ $body 19 $true; $s = $cd.Sketches.Add($tf)
$pts = @( @(-50.0, 50.0), @(-50.0, -4.84), @(4.84, 50.0) )
$sp = @()
foreach ($pt in $pts) { $sp += $s.SketchPoints.Add($tg.CreatePoint2d((MM $pt[0]), (MM $pt[1])), $false) }
for ($i = 0; $i -lt 3; $i++) { $null = $s.SketchLines.AddByTwoPoints($sp[$i], $sp[($i + 1) % 3]) }
$ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kCut)
$ed.SetDistanceExtent((MM 22), $kNeg); $null = $cd.Features.ExtrudeFeatures.Add($ed)

# Step 7: 2 BOTTOM slots (z=0→3, outside cavity)
Write-Host "Step 7: 2 BOTTOM slots depth 3..." -ForegroundColor Cyan
$bf = FindZ $body 0 $false
if (-not $bf) { $bf = FindZ $body 0 $true }
if ($bf) {
    $s = $cd.Sketches.Add($bf)
    AddRect $s $tg -3.5 26.5 3.5 31.0
    AddRect $s $tg -3.5 -31.0 3.5 -26.5
    $ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kCut)
    $ed.SetDistanceExtent((MM 3), $kNeg); $null = $cd.Features.ExtrudeFeatures.Add($ed)
}

# Step 8: 2 TOP slots (z=19→9, depth 10)
Write-Host "Step 8: 2 TOP slots depth 10..." -ForegroundColor Cyan
$tf = FindZ $body 19 $true
if ($tf) {
    $s = $cd.Sketches.Add($tf)
    AddRect $s $tg -3.5 26.5 3.5 31.0
    AddRect $s $tg -3.5 -31.0 3.5 -26.5
    $ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kCut)
    $ed.SetDistanceExtent((MM 10), $kNeg); $null = $cd.Features.ExtrudeFeatures.Add($ed)
}

# Read back
$body = $cd.SurfaceBodies.Item(1); $mp = $cd.MassProperties; $rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 1)
Write-Host ""
Write-Host ("BBox: {0} × {1} × {2}  (target 70 × 70 × 19)" -f $xL,$yL,$zL) -ForegroundColor Green
Write-Host ("Vol:  {0} mm³  (target 29,843 → diff {1:F2}%)" -f $vAct, ((($vAct - 29842.7)/29842.7)*100)) -ForegroundColor Green

$out = "$env:USERPROFILE\Desktop\test\round7_KE-BH-069_left\my_attempt.ipt"
$doc.SaveAs($out, $false)
Write-Host "Saved: $out" -ForegroundColor Green
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
