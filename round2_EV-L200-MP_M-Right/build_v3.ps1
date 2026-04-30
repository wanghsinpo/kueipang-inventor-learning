## Round 2 v3 — adds the 2 outline slots that v2 was missing.
## Slots: 7mm wide in X (x = ±3.5), extending in Y from ±17.99 to outer Ø75 perimeter.
## Cut through full Z thickness (21.5mm).
## Expected: V drops from 49,988 → ~44,100 (vs real 43,734).

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('Nag8' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class Nag8 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-Nag8([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class N8 {
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
            [N8]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][N8]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][N8]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [N8]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][N8]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481; $kCut=20482; $kPos=20993; $kNeg=20994

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-Nag8 $invPid
try { $inv.Documents.CloseAll($false) } catch { }

$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd = $doc.ComponentDefinition
$tg = $inv.TransientGeometry

# Helper: rectangle by 4 points (using SketchPoints first - lesson from R1)
function AddRect($s, $x1, $y1, $x2, $y2) {
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

# Step 1: Pad Ø75 cylinder
Write-Host "Step 1: Pad Ø75 × 21.5..." -ForegroundColor Cyan
$xy = $cd.WorkPlanes.Item(3)
$s1 = $cd.Sketches.Add($xy)
$null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 37.5))
$prof1 = $s1.Profiles.AddForSolid()
$ed1 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof1, $kJoin)
$ed1.SetDistanceExtent((MM 21.5), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed1)

# Step 2: Cut Ø52 cavity from top
Write-Host "Step 2: Cut Ø52 cavity from top, depth 20mm..." -ForegroundColor Cyan
$body = $cd.SurfaceBodies.Item(1)
$topFace = $null
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 21.5)) -lt 0.01 -and $n.Z -gt 0.5) { $topFace = $f; break }
}
$s2 = $cd.Sketches.Add($topFace)
$null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 26))
$prof2 = $s2.Profiles.AddForSolid()
$ed2 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof2, $kCut)
$ed2.SetDistanceExtent((MM 20), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed2)

# Step 3: 2 M5 holes Ø4.13 at (0, ±31.5)
Write-Host "Step 3: 2 M5 holes (Ø4.13) at (0, ±31.5)..." -ForegroundColor Cyan
$tf = $null
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 21.5)) -lt 0.01 -and $n.Z -gt 0.5 -and $f.Evaluator.Area -gt 0.1) { $tf = $f; break }
}
$s3 = $cd.Sketches.Add($tf)
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 0), (MM 31.5)), (MM 2.067))
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 0), (MM -31.5)), (MM 2.067))
$prof3 = $s3.Profiles.AddForSolid()
$ed3 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3, $kCut)
$ed3.SetDistanceExtent((MM 25), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed3)

# Step 4: 2 Ø5 thru at (±31.5, 0)
Write-Host "Step 4: 2 Ø5 thru at (±31.5, 0)..." -ForegroundColor Cyan
$tf = $null
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 21.5)) -lt 0.01 -and $n.Z -gt 0.5 -and $f.Evaluator.Area -gt 0.1) { $tf = $f; break }
}
$s4 = $cd.Sketches.Add($tf)
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 31.5), (MM 0)), (MM 2.5))
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM -31.5), (MM 0)), (MM 2.5))
$prof4 = $s4.Profiles.AddForSolid()
$ed4 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof4, $kCut)
$ed4.SetDistanceExtent((MM 25), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed4)

# Step 5: 2 Ø7.9 c'bores deep 5.5
Write-Host "Step 5: 2 Ø7.9 c'bores deep 5.5..." -ForegroundColor Cyan
$tf = $null
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 21.5)) -lt 0.01 -and $n.Z -gt 0.5 -and $f.Evaluator.Area -gt 0.1) { $tf = $f; break }
}
$s5 = $cd.Sketches.Add($tf)
$null = $s5.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 31.5), (MM 0)), (MM 3.95))
$null = $s5.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM -31.5), (MM 0)), (MM 3.95))
$prof5 = $s5.Profiles.AddForSolid()
$ed5 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof5, $kCut)
$ed5.SetDistanceExtent((MM 5.5), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed5)

# Step 6: 2 internal slots cut from BOTTOM (z=0) going UP by 9mm.
# Slots stay INSIDE Ø75 perimeter (real BBox is 75 × 75, not reduced by slots).
# Walls at x=±3.5, Y from ±17.99 to outer Ø75 boundary.
Write-Host "Step 6: 2 bottom-pocket slots (depth 9 from z=0)..." -ForegroundColor Cyan
# Find largest planar face at z=0 (don't care about normal direction)
$bottomFace = $null; $maxArea = 0
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }
    $r = $f.Geometry.RootPoint; $n = $f.Geometry.Normal
    if ([Math]::Abs($r.Z - (MM 0)) -lt 0.01 -and [Math]::Abs($n.Z) -gt 0.5) {
        $a = $f.Evaluator.Area
        if ($a -gt $maxArea) { $maxArea = $a; $bottomFace = $f }
    }
}
if ($null -eq $bottomFace) { throw "Could not find bottom face at z=0" }
Write-Host ("  Found bottom face area={0:F1} mm²" -f ($maxArea*100)) -ForegroundColor DarkGray
$s6 = $cd.Sketches.Add($bottomFace)
# When sketching on bottom face, sketch X may be flipped — but rectangles are symmetric so OK.
# Top slot: stays inside Ø75. Y from 17.99 up to 37.0 (just inside Ø75 boundary).
AddRect $s6 -3.5  17.99  3.5  37.0
AddRect $s6 -3.5 -37.0   3.5 -17.99
$prof6 = $s6.Profiles.AddForSolid()
$ed6 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof6, $kCut)
# Cut INTO body (sketch is on bottom face, body is above; "positive" sketch direction is away from body, so use negative)
$ed6.SetDistanceExtent((MM 9), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed6)

# Read back
$body = $cd.SurfaceBodies.Item(1)
$mp = $cd.MassProperties
$rb = $body.RangeBox
$xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
$yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
$zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
$vAct = [Math]::Round($mp.Volume * 1000, 1)
Write-Host ""
Write-Host ("BBox: {0} × {1} × {2}  (target 75 × 75 × 21.5)" -f $xL,$yL,$zL) -ForegroundColor Green
Write-Host ("Vol:  {0} mm³  (target 43,734 → diff {1:F2}%)" -f $vAct, ((($vAct - 43734.2)/43734.2)*100)) -ForegroundColor Green

$out = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt_v3.ipt"
$doc.SaveAs($out, $false)
Write-Host "Saved: $out" -ForegroundColor Green

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
