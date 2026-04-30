## Round 2 v6 — fix slot errors:
##   1. Move bottom slots OUTWARD (y=[26.5, 32]) so they don't overlap cavity (R=26)
##   2. ADD 2 top-face slots from z=21.5 down to z=9 (depth 12.5)
##   3. Slots don't go through (top slot stops at z=9, bottom stops at z=3, gap of 6mm)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

if (-not ('NagB' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagB {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagB([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NB {
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
            [NB]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NB]::GetWindowText($h, $sb, 256)
                [uint32]$wp=0; [void][NB]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NB]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) { $script:hits.Add($h) }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NB]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$kPart=12290; $kJoin=20481; $kCut=20482; $kPos=20993; $kNeg=20994

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor).Id)
$nagJob = Start-NagB $invPid
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
$cd = $doc.ComponentDefinition
$tg = $inv.TransientGeometry

# Step 1: Pad Ø75
Write-Host "Step 1: Pad Ø75 × 21.5..." -ForegroundColor Cyan
$xy = $cd.WorkPlanes.Item(3)
$s1 = $cd.Sketches.Add($xy)
$null = $s1.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 37.5))
$prof1 = $s1.Profiles.AddForSolid()
$ed1 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof1, $kJoin)
$ed1.SetDistanceExtent((MM 21.5), $kPos)
$null = $cd.Features.ExtrudeFeatures.Add($ed1)
$body = $cd.SurfaceBodies.Item(1)

# Step 2: Cut Ø52 cavity
Write-Host "Step 2: Cut Ø52 cavity from top, depth 20..." -ForegroundColor Cyan
$tf = FindZ $body 21.5 $true
$s2 = $cd.Sketches.Add($tf)
$null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 26))
$prof2 = $s2.Profiles.AddForSolid()
$ed2 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof2, $kCut)
$ed2.SetDistanceExtent((MM 20), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed2)

# Step 3: 2 M5 holes Ø4.13 at (0, ±31.5)
Write-Host "Step 3: 2 M5 holes..." -ForegroundColor Cyan
$tf = FindZ $body 21.5 $true
$s3 = $cd.Sketches.Add($tf)
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 0), (MM 31.5)), (MM 2.067))
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 0), (MM -31.5)), (MM 2.067))
$prof3 = $s3.Profiles.AddForSolid()
$ed3 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3, $kCut)
$ed3.SetDistanceExtent((MM 25), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed3)

# Step 4: 2 Ø5 thru at (±31.5, 0)
Write-Host "Step 4: 2 Ø5 thru..." -ForegroundColor Cyan
$tf = FindZ $body 21.5 $true
$s4 = $cd.Sketches.Add($tf)
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 31.5), (MM 0)), (MM 2.5))
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM -31.5), (MM 0)), (MM 2.5))
$prof4 = $s4.Profiles.AddForSolid()
$ed4 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof4, $kCut)
$ed4.SetDistanceExtent((MM 25), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed4)

# Step 5: 2 Ø7.9 c'bores
Write-Host "Step 5: 2 Ø7.9 × 5.5 c'bores..." -ForegroundColor Cyan
$tf = FindZ $body 21.5 $true
$s5 = $cd.Sketches.Add($tf)
$null = $s5.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM 31.5), (MM 0)), (MM 3.95))
$null = $s5.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM -31.5), (MM 0)), (MM 3.95))
$prof5 = $s5.Profiles.AddForSolid()
$ed5 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof5, $kCut)
$ed5.SetDistanceExtent((MM 5.5), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed5)

# Step 6: NW chord cut
Write-Host "Step 6: NW chord cut..." -ForegroundColor Cyan
$tf = FindZ $body 21.5 $true
$s6 = $cd.Sketches.Add($tf)
$pts = @( @(-50.0, 50.0), @(-50.0, -4.8), @(4.8, 50.0) )
$sp = @()
foreach ($pt in $pts) { $sp += $s6.SketchPoints.Add($tg.CreatePoint2d((MM $pt[0]), (MM $pt[1])), $false) }
for ($i = 0; $i -lt 3; $i++) { $null = $s6.SketchLines.AddByTwoPoints($sp[$i], $sp[($i + 1) % 3]) }
$prof6 = $s6.Profiles.AddForSolid()
$ed6 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof6, $kCut)
$ed6.SetDistanceExtent((MM 25), $kNeg)
$null = $cd.Features.ExtrudeFeatures.Add($ed6)

# Step 7: 2 BOTTOM slots — outside cavity (y=[26.5, 32]), depth 3
# Width 7mm (x=±3.5). Slot stops at z=3 (does NOT reach cavity floor at z=1.5).
# Wait — z=0 to z=3 INCLUDES z=1.5 (cavity floor). So overlap exists.
# Solution: keep slot OUTSIDE cavity radius. Cavity is R<26, so x=±3.5 + y in [26.5, 32] is outside.
# At x=3.5, cavity boundary y = √(26²-3.5²) = 25.76. So y=26.5 is just outside.
Write-Host "Step 7: 2 BOTTOM slots (y=[26.5, 32], outside cavity), depth 3..." -ForegroundColor Cyan
$bf = FindZ $body 0 $false
if (-not $bf) { $bf = FindZ $body 0 $true }   # fallback
if ($bf) {
    $s7 = $cd.Sketches.Add($bf)
    AddRect $s7 $tg -3.5 26.5 3.5 32.0
    AddRect $s7 $tg -3.5 -32.0 3.5 -26.5
    $prof7 = $s7.Profiles.AddForSolid()
    $ed7 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof7, $kCut)
    $ed7.SetDistanceExtent((MM 3), $kNeg)
    $null = $cd.Features.ExtrudeFeatures.Add($ed7)
} else {
    Write-Host "  WARN: bottom face not found, skip bottom slots" -ForegroundColor Yellow
}

# Step 8: 2 TOP-face slots — cut DOWN from z=21.5 by 12.5mm (to z=9)
# Same XY position as bottom slots: y=[26.5, 32], x=±3.5
# These are inside the cavity radius (when viewed from top, slots are in the annular ring
# between cavity and outer cylinder). Wait NO — these are OUTSIDE the cavity wall (R=26).
# So they're cuts in the annular ring on top face going down 12.5mm.
Write-Host "Step 8: 2 TOP-face slots (cut DOWN 12.5 from z=21.5)..." -ForegroundColor Cyan
$tf = FindZ $body 21.5 $true
if ($tf) {
    $s8 = $cd.Sketches.Add($tf)
    AddRect $s8 $tg -3.5 26.5 3.5 32.0
    AddRect $s8 $tg -3.5 -32.0 3.5 -26.5
    $prof8 = $s8.Profiles.AddForSolid()
    $ed8 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof8, $kCut)
    $ed8.SetDistanceExtent((MM 12.5), $kNeg)
    $null = $cd.Features.ExtrudeFeatures.Add($ed8)
}

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

$out = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt_v6.ipt"
$doc.SaveAs($out, $false)
Write-Host "Saved: $out" -ForegroundColor Green

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
