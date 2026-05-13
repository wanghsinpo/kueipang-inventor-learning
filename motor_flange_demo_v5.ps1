## motor_flange_demo_v2.ps1
## v2 — fix the errors from v1, add missing features.
##
## Changes from v1:
##  + Add Pocket (Ø68 × 3mm ring recess around hub)
##  + Add CounterBore (Ø42 × 4mm step on hub top — bearing seat)
##  + Add 4 threaded holes M4 (Ø3.3) on PCD 60 in pocket bottom
##  + Add 2 threaded holes M4 on plate top (above hub)
##  + Add 2 dowel pin holes Ø3 on plate bottom (below hub area)
##  + Fix Keyway: small U-notch 8x4 instead of 14x6
##  + Plate height 80mm (was 88) — closer to photo proportions
##  + Mounting holes Ø8.5 (M8) at corner offset (38, 34)
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File motor_flange_demo_v2.ps1

param(
    [double]$PlateW       = 88.0,
    [double]$PlateH       = 80.0,
    [double]$PlateT       = 12.0,
    [double]$Chamf        = 14.0,
    [double]$HubD         = 50.0,
    [double]$HubH         = 8.0,
    [double]$CBD          = 42.0,    # counter-bore diameter
    [double]$CBDepth      = 4.0,     # counter-bore depth
    [double]$BoreD        = 32.0,
    [double]$PocketOD     = 68.0,    # pocket outer diameter
    [double]$PocketDepth  = 3.0,
    [double]$HoleD        = 8.5,     # 4 corner mounting holes (M8)
    [double]$HoleX        = 38.0,
    [double]$HoleY        = 34.0,
    [double]$KeyW         = 8.0,
    [double]$KeyDepth     = 4.0,
    [double]$ThreadD      = 3.3,     # M4 tap pilot
    [double]$ThreadPCD    = 60.0,
    [int]   $ThreadCount  = 4,
    [double]$ThreadDepth  = 8.0,     # blind depth
    [double]$TopThreadY   = 28.0,    # 2 M4 holes near top edge
    [double]$TopThreadX   = 16.0,    # ± from center
    [double]$DowelD       = 3.0,
    [double]$DowelY       = -28.0,   # 2 dowel holes below hub
    [double]$DowelX       = 9.0,     # ± from center
    [double]$ChamfHole    = 0.5,     # chamfer for hole entries
    [double]$ChamfPlate   = 1.0,     # plate top/bottom outer edge chamfer
    [double]$CSinkD       = 14.0,    # 4 corner hole countersink diameter
    [double]$CSinkDepth   = 3.0,     # countersink depth
    [double]$HubFilletR   = 1.5,     # fillet at hub-plate junction
    [string]$Name         = "motor_flange_v5",
    [string]$OutFolder    = "$env:USERPROFILE\Desktop\test\motor_flange_demo"
)

$ErrorActionPreference = 'Stop'
function MM($v) { return [double]$v / 10.0 }

$kPart = 12290; $kJoin = 20481; $kCut = 20482; $kPos = 20993; $kNeg = 20994

# nag-watcher
if (-not ('NagMF2' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagMF2 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}

Write-Host "=== motor_flange_demo_v2.ps1 ===" -ForegroundColor Cyan

# connect
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
} catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application'))
    Start-Sleep -Seconds 3
}
$inv.Visible = $true

try { $inv.Documents.CloseAll($false) } catch { }
$tpl = $inv.FileManager.GetTemplateFile($kPart)
$doc = $inv.Documents.Add($kPart, $tpl, $true)
$cd  = $doc.ComponentDefinition
$tg  = $inv.TransientGeometry

# ============================================================
# 01 — BasePlate (octagon)
# ============================================================
Write-Host "[01] BasePlate..." -ForegroundColor Yellow
$xy = $cd.WorkPlanes.Item(3)
$s1 = $cd.Sketches.Add($xy)

$hw    = [double]($PlateW / 2.0)
$hh    = [double]($PlateH / 2.0)
$c     = [double]$Chamf
$mhw   = [double](-$hw)
$mhh   = [double](-$hh)
$hhmc  = [double]($hh - $c)
$mhhpc = [double]($mhh + $c)
$mhwpc = [double]($mhw + $c)
$hwmc  = [double]($hw - $c)

$sp = New-Object 'System.Collections.ArrayList'
[void]$sp.Add($s1.SketchPoints.Add($tg.CreatePoint2d((MM $mhw),   (MM $hhmc)),  $false))
[void]$sp.Add($s1.SketchPoints.Add($tg.CreatePoint2d((MM $mhwpc), (MM $hh)),    $false))
[void]$sp.Add($s1.SketchPoints.Add($tg.CreatePoint2d((MM $hwmc),  (MM $hh)),    $false))
[void]$sp.Add($s1.SketchPoints.Add($tg.CreatePoint2d((MM $hw),    (MM $hhmc)),  $false))
[void]$sp.Add($s1.SketchPoints.Add($tg.CreatePoint2d((MM $hw),    (MM $mhhpc)), $false))
[void]$sp.Add($s1.SketchPoints.Add($tg.CreatePoint2d((MM $hwmc),  (MM $mhh)),   $false))
[void]$sp.Add($s1.SketchPoints.Add($tg.CreatePoint2d((MM $mhwpc), (MM $mhh)),   $false))
[void]$sp.Add($s1.SketchPoints.Add($tg.CreatePoint2d((MM $mhw),   (MM $mhhpc)), $false))
for ($i = 0; $i -lt 8; $i++) {
    $null = $s1.SketchLines.AddByTwoPoints($sp[$i], $sp[($i + 1) % 8])
}
$prof1 = $s1.Profiles.AddForSolid()
$ed1   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof1, $kJoin)
$ed1.SetDistanceExtent((MM $PlateT), $kPos)
$f1    = $cd.Features.ExtrudeFeatures.Add($ed1)
$f1.Name = "01_BasePlate_${PlateW}x${PlateH}x${PlateT}"
Write-Host "  ✓ $($f1.Name)"

# offset work plane: plate top
$wpTop = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM $PlateT))
$wpTop.Visible = $false

# ============================================================
# 02 — Hub (Ø50 × 8mm above plate)
# ============================================================
Write-Host "[02] Hub..." -ForegroundColor Yellow
$s2 = $cd.Sketches.Add($wpTop)
$null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($HubD / 2.0)))
$prof2 = $s2.Profiles.AddForSolid()
$ed2   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof2, $kJoin)
$ed2.SetDistanceExtent((MM $HubH), $kPos)
$f2    = $cd.Features.ExtrudeFeatures.Add($ed2)
$f2.Name = "02_Hub_D${HubD}xH${HubH}"
Write-Host "  ✓ $($f2.Name)"

# ============================================================
# 03 — Pocket (ring recess Ø50–Ø68, 3mm deep, around hub)
# ============================================================
Write-Host "[03] Pocket (ring Ø$HubD–Ø$PocketOD, depth $PocketDepth)..." -ForegroundColor Yellow
$s3 = $cd.Sketches.Add($wpTop)
# outer circle Ø68 + inner circle Ø50 = ring profile (auto-detected)
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($PocketOD / 2.0)))
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($HubD / 2.0)))
$prof3 = $s3.Profiles.AddForSolid()
$ed3   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3, $kCut)
$ed3.SetDistanceExtent((MM $PocketDepth), $kNeg)
$f3    = $cd.Features.ExtrudeFeatures.Add($ed3)
$f3.Name = "03_Pocket_Ring_D${PocketOD}_d${PocketDepth}"
Write-Host "  ✓ $($f3.Name)"

# ============================================================
# 04 — CounterBore (Ø42, 4mm deep into hub top — bearing seat)
# ============================================================
Write-Host "[04] CounterBore..." -ForegroundColor Yellow
$wpHubTop = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM ($PlateT + $HubH)))
$wpHubTop.Visible = $false
$s4 = $cd.Sketches.Add($wpHubTop)
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($CBD / 2.0)))
$prof4 = $s4.Profiles.AddForSolid()
$ed4   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof4, $kCut)
$ed4.SetDistanceExtent((MM $CBDepth), $kNeg)
$f4    = $cd.Features.ExtrudeFeatures.Add($ed4)
$f4.Name = "04_CounterBore_D${CBD}_d${CBDepth}"
Write-Host "  ✓ $($f4.Name)"

# ============================================================
# 05 — CenterBore (Ø32 through all)
# ============================================================
Write-Host "[05] CenterBore..." -ForegroundColor Yellow
$s5 = $cd.Sketches.Add($wpHubTop)
$null = $s5.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($BoreD / 2.0)))
$prof5 = $s5.Profiles.AddForSolid()
$ed5   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof5, $kCut)
$ed5.SetDistanceExtent((MM ($PlateT + $HubH + 2)), $kNeg)
$f5    = $cd.Features.ExtrudeFeatures.Add($ed5)
$f5.Name = "05_CenterBore_D${BoreD}"
Write-Host "  ✓ $($f5.Name)"

# offset work plane: slightly above plate top for downward cuts
$wpAbove = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM ($PlateT + 0.01)))
$wpAbove.Visible = $false

# ============================================================
# 06 — MountingHoles (4× Ø8.5 corner holes, through)
# ============================================================
Write-Host "[06] MountingHoles 4xD$HoleD..." -ForegroundColor Yellow
$s6 = $cd.Sketches.Add($wpAbove)
foreach ($x in @(-$HoleX, $HoleX)) {
    foreach ($y in @(-$HoleY, $HoleY)) {
        $null = $s6.SketchCircles.AddByCenterRadius(
            $tg.CreatePoint2d((MM $x), (MM $y)), (MM ($HoleD / 2.0)))
    }
}
$prof6 = $s6.Profiles.AddForSolid()
$ed6   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof6, $kCut)
$ed6.SetDistanceExtent((MM ($PlateT + 2)), $kNeg)
$f6    = $cd.Features.ExtrudeFeatures.Add($ed6)
$f6.Name = "06_MountingHoles_4xD${HoleD}"
Write-Host "  ✓ $($f6.Name)"

# ============================================================
# 07 — Keyway (small U-notch on bottom edge)
# ============================================================
Write-Host "[07] Keyway (${KeyW}x${KeyDepth} U-notch)..." -ForegroundColor Yellow
$s7 = $cd.Sketches.Add($wpAbove)
$kx1 = [double](-$KeyW / 2.0)
$kx2 = [double]( $KeyW / 2.0)
$ky1 = [double](-$hh - 1)
$ky2 = [double](-$hh + $KeyDepth)
$p_k1 = $tg.CreatePoint2d((MM $kx1), (MM $ky1))
$p_k2 = $tg.CreatePoint2d((MM $kx2), (MM $ky2))
$null = $s7.SketchLines.AddAsTwoPointRectangle($p_k1, $p_k2)
$prof7 = $s7.Profiles.AddForSolid()
$ed7   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof7, $kCut)
$ed7.SetDistanceExtent((MM ($PlateT + 2)), $kNeg)
$f7    = $cd.Features.ExtrudeFeatures.Add($ed7)
$f7.Name = "07_Keyway_W${KeyW}xD${KeyDepth}"
Write-Host "  ✓ $($f7.Name)"

# ============================================================
# 08 — Pocket threaded holes (4× M4 on PCD 60, in pocket bottom)
# ============================================================
Write-Host "[08] PocketThreadedHoles 4xM4 (Ø$ThreadD on PCD$ThreadPCD)..." -ForegroundColor Yellow
$wpPocketBot = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM ($PlateT - $PocketDepth + 0.01)))
$wpPocketBot.Visible = $false
$s8 = $cd.Sketches.Add($wpPocketBot)
$pcdR = [double]($ThreadPCD / 2.0)
for ($i = 0; $i -lt $ThreadCount; $i++) {
    $angleDeg = [double]($i * 360.0 / $ThreadCount + 45.0)
    $angleRad = [double]($angleDeg * [Math]::PI / 180.0)
    $cosA = [double][Math]::Cos($angleRad)
    $sinA = [double][Math]::Sin($angleRad)
    $tx = [double]($pcdR * $cosA)
    $ty = [double]($pcdR * $sinA)
    $null = $s8.SketchCircles.AddByCenterRadius(
        $tg.CreatePoint2d((MM $tx), (MM $ty)), (MM ($ThreadD / 2.0)))
}
$prof8 = $s8.Profiles.AddForSolid()
$ed8   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof8, $kCut)
$ed8.SetDistanceExtent((MM $ThreadDepth), $kNeg)
$f8    = $cd.Features.ExtrudeFeatures.Add($ed8)
$f8.Name = "08_PocketThreaded_4xM4"
Write-Host "  ✓ $($f8.Name)"

# ============================================================
# 09 — Top edge M4 threaded holes (2× near top edge)
# ============================================================
Write-Host "[09] TopThreadedHoles 2xM4..." -ForegroundColor Yellow
$s9 = $cd.Sketches.Add($wpAbove)
$null = $s9.SketchCircles.AddByCenterRadius(
    $tg.CreatePoint2d((MM -$TopThreadX), (MM $TopThreadY)), (MM ($ThreadD / 2.0)))
$null = $s9.SketchCircles.AddByCenterRadius(
    $tg.CreatePoint2d((MM  $TopThreadX), (MM $TopThreadY)), (MM ($ThreadD / 2.0)))
$prof9 = $s9.Profiles.AddForSolid()
$ed9   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof9, $kCut)
$ed9.SetDistanceExtent((MM $ThreadDepth), $kNeg)
$f9    = $cd.Features.ExtrudeFeatures.Add($ed9)
$f9.Name = "09_TopThreaded_2xM4"
Write-Host "  ✓ $($f9.Name)"

# ============================================================
# 10 — Dowel pin holes (2× Ø3 below hub area)
# ============================================================
Write-Host "[10] DowelPinHoles 2xD$DowelD..." -ForegroundColor Yellow
$s10 = $cd.Sketches.Add($wpAbove)
$null = $s10.SketchCircles.AddByCenterRadius(
    $tg.CreatePoint2d((MM -$DowelX), (MM $DowelY)), (MM ($DowelD / 2.0)))
$null = $s10.SketchCircles.AddByCenterRadius(
    $tg.CreatePoint2d((MM  $DowelX), (MM $DowelY)), (MM ($DowelD / 2.0)))
$prof10 = $s10.Profiles.AddForSolid()
$ed10   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof10, $kCut)
$ed10.SetDistanceExtent((MM ($PlateT + 2)), $kNeg)
$f10    = $cd.Features.ExtrudeFeatures.Add($ed10)
$f10.Name = "10_DowelPins_2xD${DowelD}"
Write-Host "  ✓ $($f10.Name)"

# ============================================================
# 11 — Plate outer edge chamfer (top/bottom outer 8-gon edges)
# Apply BEFORE circle chamfer so plate edges are still simple lines
# ============================================================
Write-Host "[11] PlateEdgeChamfer C$ChamfPlate (top + bottom outer 8 edges)..." -ForegroundColor Yellow
$body = $cd.SurfaceBodies.Item(1)
$plateEdges = $inv.TransientObjects.CreateEdgeCollection()
$plateEdgesAdded = 0

# Find plate top + bottom face by Z position (more reliable than normal direction)
$plateTopFace = $null; $plateBotFace = $null
$targetTopZ = [double]($PlateT / 10.0)   # cm internal
$targetBotZ = 0.0
$bestTopDist = 9999; $bestBotDist = 9999
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -eq 5890) {
        $pof = $f.PointOnFace
        $area = $f.Evaluator.Area
        if ($area -lt 1) { continue }   # skip tiny faces
        $distTop = [Math]::Abs($pof.Z - $targetTopZ)
        $distBot = [Math]::Abs($pof.Z - $targetBotZ)
        if ($distTop -lt 0.05 -and $distTop -lt $bestTopDist) {
            $bestTopDist = $distTop; $plateTopFace = $f
        }
        if ($distBot -lt 0.05 -and $distBot -lt $bestBotDist) {
            $bestBotDist = $distBot; $plateBotFace = $f
        }
    }
}

foreach ($face in @($plateTopFace, $plateBotFace)) {
    if ($face) {
        Write-Host "  Face: area=$([Math]::Round($face.Evaluator.Area*100,1))mm² loops=$($face.EdgeLoops.Count)" -ForegroundColor DarkGray
        foreach ($loop in $face.EdgeLoops) {
            if ($loop.IsOuterEdgeLoop) {
                Write-Host "    OuterLoop edges=$($loop.Edges.Count)" -ForegroundColor DarkGray
                foreach ($e in $loop.Edges) {
                    [void]$plateEdges.Add($e)
                    $plateEdgesAdded++
                }
                break
            }
        }
    } else {
        Write-Host "  Face NOT FOUND" -ForegroundColor Red
    }
}

if ($plateEdgesAdded -gt 0) {
    try {
        $f11 = $cd.Features.ChamferFeatures.AddUsingDistance($plateEdges, (MM $ChamfPlate), $false)
        $f11.Name = "11_PlateEdgeChamfer_C${ChamfPlate}"
        Write-Host "  ✓ $($f11.Name) — $plateEdgesAdded line edges" -ForegroundColor Green
    } catch {
        Write-Host "  Plate edge chamfer failed: $_" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  No line edges found" -ForegroundColor DarkYellow
}

# ============================================================
# 12 — Chamfer all circular edges (hole entries, hub top, bore)
# ============================================================
Write-Host "[12] ChamferCircles C$ChamfHole (all circular edges)..." -ForegroundColor Yellow
$ecChamf = $inv.TransientObjects.CreateEdgeCollection()
$edgeCount = 0
foreach ($e in $body.Edges) {
    if ($e.GeometryType -eq 5124) {
        [void]$ecChamf.Add($e)
        $edgeCount++
    }
}
if ($edgeCount -gt 0) {
    try {
        $f12 = $cd.Features.ChamferFeatures.AddUsingDistance($ecChamf, (MM $ChamfHole), $false)
        $f12.Name = "12_ChamferCircles_C${ChamfHole}"
        Write-Host "  ✓ $($f12.Name) — $edgeCount edges" -ForegroundColor Green
    } catch {
        Write-Host "  Circle chamfer failed: $_" -ForegroundColor DarkYellow
    }
}

# ============================================================
# 13 — Corner mounting hole countersinks (4× Ø14 × 3mm)
# ============================================================
Write-Host "[13] CornerCountersink (4x Ø$CSinkD × ${CSinkDepth}mm)..." -ForegroundColor Yellow
$s13 = $cd.Sketches.Add($wpAbove)
foreach ($x in @(-$HoleX, $HoleX)) {
    foreach ($y in @(-$HoleY, $HoleY)) {
        $null = $s13.SketchCircles.AddByCenterRadius(
            $tg.CreatePoint2d((MM $x), (MM $y)), (MM ($CSinkD / 2.0)))
    }
}
$prof13 = $s13.Profiles.AddForSolid()
$ed13   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof13, $kCut)
$ed13.SetDistanceExtent((MM $CSinkDepth), $kNeg)
$f13    = $cd.Features.ExtrudeFeatures.Add($ed13)
$f13.Name = "13_CornerCountersink_4xD${CSinkD}_d${CSinkDepth}"
Write-Host "  ✓ $($f13.Name)" -ForegroundColor Green

# ============================================================
# 14 — Hub base fillet (where hub meets pocket bottom)
# ============================================================
Write-Host "[14] HubBaseFillet R${HubFilletR}..." -ForegroundColor Yellow
# Find the circle at z=PlateT-PocketDepth with radius=HubD/2 (hub base in pocket)
$hubFilletEdges = $inv.TransientObjects.CreateEdgeCollection()
$targetZ = [double](($PlateT - $PocketDepth) / 10.0)
$targetR = [double](($HubD / 2.0) / 10.0)
foreach ($e in $body.Edges) {
    if ($e.GeometryType -eq 5124) {
        try {
            $g = $e.Geometry
            $rDiff = [Math]::Abs($g.Radius - $targetR)
            $zDiff = [Math]::Abs($g.Center.Z - $targetZ)
            if ($rDiff -lt 0.02 -and $zDiff -lt 0.02) {
                [void]$hubFilletEdges.Add($e)
            }
        } catch {}
    }
}
if ($hubFilletEdges.Count -gt 0) {
    try {
        $f14 = $cd.Features.FilletFeatures.AddSimple($hubFilletEdges, (MM $HubFilletR))
        $f14.Name = "14_HubBaseFillet_R${HubFilletR}"
        Write-Host "  ✓ $($f14.Name) — $($hubFilletEdges.Count) edge(s)" -ForegroundColor Green
    } catch {
        Write-Host "  Hub fillet failed: $_" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  Hub base edge not found" -ForegroundColor DarkYellow
}

# measure + save
$body = $cd.SurfaceBodies.Item(1)
$rb   = $body.RangeBox
$vol  = [Math]::Round($cd.MassProperties.Volume * 1000, 1)
$bbW  = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 1)
$bbH  = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 1)
$bbT  = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 1)
Write-Host ""
Write-Host "Result: BBox $bbW x $bbH x $bbT  Vol=$vol mm³" -ForegroundColor Magenta

if (-not (Test-Path $OutFolder)) { New-Item -ItemType Directory -Path $OutFolder | Out-Null }
$outPath = Join-Path $OutFolder "$Name.ipt"
$doc.SaveAs($outPath, $false)
Write-Host "Saved: $outPath" -ForegroundColor Cyan

# iso preview
try {
    $view = $inv.ActiveView
    $cam = $view.Camera
    $cam.Eye    = $tg.CreatePoint(30, -30, 30)
    $cam.Target = $tg.CreatePoint(0, 0, 1)
    $cam.UpVector = $tg.CreateUnitVector(0, 0, 1)
    $cam.Apply()
    $view.Fit()
    Start-Sleep -Milliseconds 400
    $view.SaveAsBitmap((Join-Path $OutFolder "v2_iso.bmp"), 1200, 900)

    # Also top view
    $cam.Eye    = $tg.CreatePoint(0, 0, 50)
    $cam.Target = $tg.CreatePoint(0, 0, 0)
    $cam.UpVector = $tg.CreateUnitVector(0, 1, 0)
    $cam.Apply()
    $view.Fit()
    Start-Sleep -Milliseconds 400
    $view.SaveAsBitmap((Join-Path $OutFolder "v2_top.bmp"), 1200, 900)

    # And bottom view (to verify back-side features)
    $cam.Eye    = $tg.CreatePoint(0, 0, -50)
    $cam.Target = $tg.CreatePoint(0, 0, 0)
    $cam.UpVector = $tg.CreateUnitVector(0, 1, 0)
    $cam.Apply()
    $view.Fit()
    Start-Sleep -Milliseconds 400
    $view.SaveAsBitmap((Join-Path $OutFolder "v2_bottom.bmp"), 1200, 900)

    # back to iso
    $cam.Eye    = $tg.CreatePoint(30, -30, 30)
    $cam.Target = $tg.CreatePoint(0, 0, 1)
    $cam.UpVector = $tg.CreateUnitVector(0, 0, 1)
    $cam.Apply()
    $view.Fit()
} catch { Write-Host "Preview failed: $_" -ForegroundColor DarkYellow }

Write-Host "=== DONE v2 (10 features) ===" -ForegroundColor Green
