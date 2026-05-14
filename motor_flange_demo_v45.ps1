## motor_flange_demo_v2.ps1
## v2 ??fix the errors from v1, add missing features.
##
## Changes from v1:
##  + Add Pocket (?68 ? 3mm ring recess around hub)
##  + Add CounterBore (?42 ? 4mm step on hub top ??bearing seat)
##  + Add 4 threaded holes M4 (?3.3) on PCD 60 in pocket bottom
##  + Add 2 threaded holes M4 on plate top (above hub)
##  + Add 2 dowel pin holes ?3 on plate bottom (below hub area)
##  + Fix Keyway: small U-notch 8x4 instead of 14x6
##  + Plate height 80mm (was 88) ??closer to photo proportions
##  + Mounting holes ?8.5 (M8) at corner offset (38, 34)
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File motor_flange_demo_v2.ps1

param(
    [double]$PlateW       = 88.0,
    [double]$PlateH       = 88.0,    # v12: was 80, photo shows more square
    [double]$PlateT       = 12.0,
    [double]$Chamf        = 14.0,
    [double]$HubD         = 52.0,    # v12: was 50, photo shows slightly larger
    [double]$HubH         = 10.0,   # v13: 8→10 — photo iso shows taller hub
    [double]$CBD          = 44.0,    # v12: was 42, scales with HubD
    [double]$CBDepth      = 4.0,
    [double]$BoreD        = 32.0,    # v22: was 32, try smaller bore
    [double]$PocketOD     = 70.0,    # v12: was 68, scales with HubD
    [double]$PocketDepth  = 4.0,
    [double]$HoleD        = 8.5,     # 4 corner mounting holes (M8)
    [double]$HoleX        = 38.0,
    [double]$HoleY        = 34.0,
    [double]$KeyW         = 8.0,
    [double]$KeyDepth     = 6.0,
    [double]$ThreadD      = 3.3,     # M4 tap pilot
    [double]$ThreadPCD    = 60.0,
    [int]   $ThreadCount  = 4,
    [double]$ThreadDepth  = 8.0,     # blind depth
    [double]$TopThreadY   = 28.0,    # 2 M4 holes near top edge
    [double]$TopThreadX   = 16.0,    # 簣 from center
    [double]$DowelD       = 3.0,
    [double]$DowelY       = -18.0,   # 2 dowel holes below hub (closer to bore per photo re-look)
    [double]$DowelX       = 10.0,    # +/- from center (slightly wider per photo re-look)
    [double]$ChamfHole    = 0.5,     # chamfer for hole entries
    [double]$ChamfPlate   = 1.5,     # plate top/bottom outer edge chamfer (v18: 1.0 -> 1.5 more visible)
    [double]$CSinkD       = 14.0,    # 4 corner hole countersink diameter
    [double]$CSinkDepth   = 3.0,     # countersink depth
    [double]$HubFilletR   = 1.5,     # fillet at hub-plate junction
    [double]$InnerKeyW    = 8.0,     # inner keyway slot width (shaft key)
    [double]$InnerKeyDepth= 4.0,     # inner keyway depth into bore wall
    [double]$ThreadDeptMin= 6.0,     # min threaded hole depth (v19: ensure adequate engagement)
    [string]$Name         = "motor_flange_v45",
    [bool]  $ExportSTEP   = $true,
    [bool]  $ExportSTL    = $true,
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
# 01 ??BasePlate (octagon)
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
Write-Host "  ??$($f1.Name)"

# offset work plane: plate top
$wpTop = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM $PlateT))
$wpTop.Visible = $false

# ============================================================
# 02 ??Hub (?50 ? 8mm above plate)
# ============================================================
Write-Host "[02] Hub..." -ForegroundColor Yellow
$s2 = $cd.Sketches.Add($wpTop)
$null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($HubD / 2.0)))
$prof2 = $s2.Profiles.AddForSolid()
$ed2   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof2, $kJoin)
$ed2.SetDistanceExtent((MM $HubH), $kPos)
$f2    = $cd.Features.ExtrudeFeatures.Add($ed2)
$f2.Name = "02_Hub_D${HubD}xH${HubH}"
Write-Host "  ??$($f2.Name)"

# ============================================================
# 03 ??Pocket (ring recess ?50??8, 3mm deep, around hub)
# ============================================================
Write-Host "[03] Pocket (ring ?$HubD??PocketOD, depth $PocketDepth)..." -ForegroundColor Yellow
$s3 = $cd.Sketches.Add($wpTop)
# outer circle ?68 + inner circle ?50 = ring profile (auto-detected)
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($PocketOD / 2.0)))
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($HubD / 2.0)))
$prof3 = $s3.Profiles.AddForSolid()
$ed3   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3, $kCut)
$ed3.SetDistanceExtent((MM $PocketDepth), $kNeg)
$f3    = $cd.Features.ExtrudeFeatures.Add($ed3)
$f3.Name = "03_Pocket_Ring_D${PocketOD}_d${PocketDepth}"
Write-Host "  ??$($f3.Name)"

# ============================================================
# 04 ??Hub base fillet (at hub-pocket junction, BEFORE chamfers)
# ============================================================
Write-Host "[04] HubBaseFillet R${HubFilletR}..." -ForegroundColor Yellow
$body0 = $cd.SurfaceBodies.Item(1)
$hubFilletEdges = $inv.TransientObjects.CreateEdgeCollection()
$targetZ = [double](($PlateT - $PocketDepth) / 10.0)
$targetR = [double](($HubD / 2.0) / 10.0)
foreach ($e in $body0.Edges) {
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
        $f4f = $cd.Features.FilletFeatures.AddSimple($hubFilletEdges, (MM $HubFilletR))
        $f4f.Name = "04_HubBaseFillet_R${HubFilletR}"
        Write-Host "  ??$($f4f.Name) ??$($hubFilletEdges.Count) edge(s)" -ForegroundColor Green
    } catch {
        Write-Host "  Hub fillet failed: $_" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  Hub base edge not found" -ForegroundColor DarkYellow
}

# ============================================================
# 05 ??CounterBore (?42, 4mm deep into hub top ??bearing seat)
# ============================================================
Write-Host "[05] CounterBore..." -ForegroundColor Yellow
$wpHubTop = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM ($PlateT + $HubH)))
$wpHubTop.Visible = $false
$s4 = $cd.Sketches.Add($wpHubTop)
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($CBD / 2.0)))
$prof4 = $s4.Profiles.AddForSolid()
$ed4   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof4, $kCut)
$ed4.SetDistanceExtent((MM $CBDepth), $kNeg)
$f4    = $cd.Features.ExtrudeFeatures.Add($ed4)
$f4.Name = "05_CounterBore_D${CBD}_d${CBDepth}"
Write-Host "  ??$($f4.Name)"

# ============================================================
# 05 ??CenterBore (?32 through all)
# ============================================================
Write-Host "[06] CenterBore..." -ForegroundColor Yellow
$s5 = $cd.Sketches.Add($wpHubTop)
$null = $s5.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0, 0), (MM ($BoreD / 2.0)))
$prof5 = $s5.Profiles.AddForSolid()
$ed5   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof5, $kCut)
$ed5.SetDistanceExtent((MM ($PlateT + $HubH + 2)), $kNeg)
$f5    = $cd.Features.ExtrudeFeatures.Add($ed5)
$f5.Name = "06_CenterBore_D${BoreD}"
Write-Host "  ??$($f5.Name)"

# ============================================================
# 6b — InnerKeyway (rectangular slot in bore wall, shaft key)
# ============================================================
Write-Host "[6b] InnerKeyway (W$InnerKeyW × D$InnerKeyDepth into bore wall)..." -ForegroundColor Yellow
$s6b = $cd.Sketches.Add($wpHubTop)
$ikx1 = [double](-$InnerKeyW / 2.0)
$ikx2 = [double]( $InnerKeyW / 2.0)
$iky1 = [double]($BoreD / 2.0 - 0.5)             # slightly inside bore wall
$iky2 = [double]($BoreD / 2.0 + $InnerKeyDepth)  # extend outward into wall
$p_ik1 = $tg.CreatePoint2d((MM $ikx1), (MM $iky1))
$p_ik2 = $tg.CreatePoint2d((MM $ikx2), (MM $iky2))
$null = $s6b.SketchLines.AddAsTwoPointRectangle($p_ik1, $p_ik2)
$prof6b = $s6b.Profiles.AddForSolid()
$ed6b   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof6b, $kCut)
$ed6b.SetDistanceExtent((MM ($PlateT + $HubH + 2)), $kNeg)
$f6b    = $cd.Features.ExtrudeFeatures.Add($ed6b)
$f6b.Name = "6b_InnerKeyway_W${InnerKeyW}xD${InnerKeyDepth}"
Write-Host "  ✓ $($f6b.Name)" -ForegroundColor Green

# offset work plane: slightly above plate top for downward cuts
$wpAbove = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM ($PlateT + 0.01)))
$wpAbove.Visible = $false

# ============================================================
# 06 ??MountingHoles (4? ?8.5 corner holes, through)
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
$f6.Name = "07_MountingHoles_4xD${HoleD}"
Write-Host "  ??$($f6.Name)"

# ============================================================
# 07 ??Keyway (small U-notch on bottom edge)
# ============================================================
Write-Host "[07] Keyway U-notch (Ø$KeyW circle at edge, becomes semicircle in plate)..." -ForegroundColor Yellow
$s7 = $cd.Sketches.Add($wpAbove)
# Simplest U-shape: full circle at plate edge — when cut, only inside-plate half affects material.
# Circle center on plate edge (y=-hh+KeyDepth-radius), radius=KeyW/2
$kHalfW = [double]($KeyW / 2.0)
$keyCenterY = [double](-$hh + $KeyDepth - $kHalfW)   # so deepest point of circle = -hh + KeyDepth
$null = $s7.SketchCircles.AddByCenterRadius(
    $tg.CreatePoint2d(0, (MM $keyCenterY)), (MM $kHalfW))
# Also a rectangle that brings the circle out past plate edge (so the cut "opens" the slot)
$pR1 = $tg.CreatePoint2d((MM -$kHalfW), (MM (-$hh - 1)))
$pR2 = $tg.CreatePoint2d((MM  $kHalfW), (MM $keyCenterY))
$null = $s7.SketchLines.AddAsTwoPointRectangle($pR1, $pR2)
$prof7 = $s7.Profiles.AddForSolid()
$ed7   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof7, $kCut)
$ed7.SetDistanceExtent((MM ($PlateT + 2)), $kNeg)
$f7    = $cd.Features.ExtrudeFeatures.Add($ed7)
$f7.Name = "08_Keyway_U_W${KeyW}xD${KeyDepth}"
Write-Host "  ✓ $($f7.Name)" -ForegroundColor Green

# ============================================================
# 08 ??Pocket threaded holes (4? M4 on PCD 60, in pocket bottom)
# ============================================================
Write-Host "[08] PocketThreadedHoles 4xM4 (?$ThreadD on PCD$ThreadPCD)..." -ForegroundColor Yellow
$wpPocketBot = $cd.WorkPlanes.AddByPlaneAndOffset($cd.WorkPlanes.Item(3), (MM ($PlateT - $PocketDepth + 0.01)))
$wpPocketBot.Visible = $false
$s8 = $cd.Sketches.Add($wpPocketBot)
$pcdR = [double]($ThreadPCD / 2.0)
for ($i = 0; $i -lt $ThreadCount; $i++) {
    $angleDeg = [double]($i * 360.0 / $ThreadCount + 0.0)   # 0/90/180/270 (was 45)
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
$f8.Name = "09_PocketThreaded_4xM4"
Write-Host "  ??$($f8.Name)"

# ============================================================
# 09 ??Top edge M4 threaded holes (2? near top edge)
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
$f9.Name = "10_TopThreaded_2xM4"
Write-Host "  ??$($f9.Name)"

# ============================================================
# 10 ??Dowel pin holes (2? ?3 below hub area)
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
$f10.Name = "11_DowelPins_2xD${DowelD}"
Write-Host "  ??$($f10.Name)"

# v15 addition: 11b — HubTopEdgeFillet (R0.3 cosmetic round on hub top circle)
Write-Host "[11b] HubTopEdgeFillet R0.3..." -ForegroundColor Yellow
$bodyV15 = $cd.SurfaceBodies.Item(1)
$hubTopEdges = $inv.TransientObjects.CreateEdgeCollection()
$hubTopZ = [double](($PlateT + $HubH) / 10.0)
$hubR = [double](($HubD / 2.0) / 10.0)
$cbR  = [double](($CBD / 2.0) / 10.0)
foreach ($e in $bodyV15.Edges) {
    if ($e.GeometryType -eq 5124) {
        try {
            $g = $e.Geometry
            $r = $g.Radius
            $z = $g.Center.Z
            # Hub top outer circle: r close to hub R, at z near top
            if (([Math]::Abs($r - $hubR) -lt 0.05 -or [Math]::Abs($r - $cbR) -lt 0.05) -and [Math]::Abs($z - $hubTopZ) -lt 0.05) {
                [void]$hubTopEdges.Add($e)
            }
        } catch {}
    }
}
if ($hubTopEdges.Count -gt 0) {
    try {
        $f11b = $cd.Features.FilletFeatures.AddSimple($hubTopEdges, (MM 0.3))
        $f11b.Name = "11b_HubTopEdgeFillet_R0.3"
        Write-Host "  ✓ $($f11b.Name) — $($hubTopEdges.Count) edge(s)" -ForegroundColor Green
    } catch { Write-Host "  Fillet failed: $_" -ForegroundColor DarkYellow }
} else {
    Write-Host "  Hub top edge not found" -ForegroundColor DarkYellow
}

# ============================================================
# 11 ??Plate outer edge chamfer (top/bottom outer 8-gon edges)
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
        Write-Host "  Face: area=$([Math]::Round($face.Evaluator.Area*100,1))mm簡 loops=$($face.EdgeLoops.Count)" -ForegroundColor DarkGray
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
        $f11.Name = "12_PlateEdgeChamfer_C${ChamfPlate}"
        Write-Host "  ??$($f11.Name) ??$plateEdgesAdded line edges" -ForegroundColor Green
    } catch {
        Write-Host "  Plate edge chamfer failed: $_" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "  No line edges found" -ForegroundColor DarkYellow
}

# ============================================================
# 12 ??Chamfer all circular edges (hole entries, hub top, bore)
# ============================================================
Write-Host "[12] ChamferCircles C$ChamfHole (filter out fillet-adjacent edges)..." -ForegroundColor Yellow
$ecChamf = $inv.TransientObjects.CreateEdgeCollection()
$edgeCount = 0
$skipped = 0
$hubBaseZ = [double](($PlateT - $PocketDepth) / 10.0)  # cm
$hubBaseR = [double](($HubD / 2.0) / 10.0)             # cm
foreach ($e in $body.Edges) {
    if ($e.GeometryType -eq 5124) {
        try {
            $g = $e.Geometry
            $z = $g.Center.Z
            $r = $g.Radius
            # Skip edges in fillet region (z near pocket bottom, r near hub OD ± fillet radius)
            $inFilletZ = [Math]::Abs($z - $hubBaseZ) -lt ($HubFilletR / 10.0 + 0.05)
            $nearHubR  = ($r -gt ($hubBaseR - 0.05)) -and ($r -lt ($hubBaseR + $HubFilletR / 10.0 + 0.05))
            if ($inFilletZ -and $nearHubR) {
                $skipped++
                continue
            }
            [void]$ecChamf.Add($e)
            $edgeCount++
        } catch {
            $skipped++
        }
    }
}
Write-Host "  Edges: $edgeCount eligible, $skipped skipped (fillet-adjacent)" -ForegroundColor DarkGray
if ($edgeCount -gt 0) {
    try {
        $f12 = $cd.Features.ChamferFeatures.AddUsingDistance($ecChamf, (MM $ChamfHole), $false)
        $f12.Name = "13_ChamferCircles_C${ChamfHole}_x$edgeCount"
        Write-Host "  ✓ $($f12.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  Batch chamfer failed — trying smaller batches" -ForegroundColor DarkYellow
        # Try splitting into 2 halves first, then quarters, etc. (binary fallback)
        $allEdges = New-Object 'System.Collections.ArrayList'
        foreach ($e in $body.Edges) {
            if ($e.GeometryType -eq 5124) {
                $g = $e.Geometry
                $z = $g.Center.Z
                $r = $g.Radius
                $inFilletZ = [Math]::Abs($z - $hubBaseZ) -lt ($HubFilletR / 10.0 + 0.05)
                $nearHubR  = ($r -gt ($hubBaseR - 0.05)) -and ($r -lt ($hubBaseR + $HubFilletR / 10.0 + 0.05))
                if (-not ($inFilletZ -and $nearHubR)) {
                    [void]$allEdges.Add($e)
                }
            }
        }
        # Try half-batches
        $halfA = $inv.TransientObjects.CreateEdgeCollection()
        $halfB = $inv.TransientObjects.CreateEdgeCollection()
        for ($i = 0; $i -lt $allEdges.Count; $i++) {
            if ($i -lt ($allEdges.Count / 2)) { [void]$halfA.Add($allEdges[$i]) }
            else { [void]$halfB.Add($allEdges[$i]) }
        }
        $consolidated = 0
        foreach ($coll in @($halfA, $halfB)) {
            if ($coll.Count -gt 0) {
                try {
                    $fHalf = $cd.Features.ChamferFeatures.AddUsingDistance($coll, (MM $ChamfHole), $false)
                    $fHalf.Name = "13_ChamferCircles_$consolidated"
                    $consolidated++
                } catch {
                    # Per-edge fallback for this batch
                    for ($j = 1; $j -le $coll.Count; $j++) {
                        $single = $inv.TransientObjects.CreateEdgeCollection()
                        [void]$single.Add($coll.Item($j))
                        try {
                            $fE = $cd.Features.ChamferFeatures.AddUsingDistance($single, (MM $ChamfHole), $false)
                            $fE.Name = "13_ChamferEdge_${consolidated}_$j"
                            $consolidated++
                        } catch {}
                    }
                }
            }
        }
        Write-Host "  ✓ Chamfer features added: $consolidated" -ForegroundColor Green
    }
}

# ============================================================
# 13 ??Corner mounting hole countersinks (4? ?14 ? 3mm)
# ============================================================
Write-Host "[13] CornerCountersink (4x ?$CSinkD ? ${CSinkDepth}mm)..." -ForegroundColor Yellow
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
$f13.Name = "14_CornerCountersink_4xD${CSinkD}_d${CSinkDepth}"
Write-Host "  ??$($f13.Name)" -ForegroundColor Green

# (Hub base fillet now moved to step 04, before chamfers)

# measure + save
$body = $cd.SurfaceBodies.Item(1)
$rb   = $body.RangeBox
$vol  = [Math]::Round($cd.MassProperties.Volume * 1000, 1)
$bbW  = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 1)
$bbH  = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 1)
$bbT  = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 1)
Write-Host ""
Write-Host "Result: BBox $bbW x $bbH x $bbT  Vol=$vol mm糧" -ForegroundColor Magenta

if (-not (Test-Path $OutFolder)) { New-Item -ItemType Directory -Path $OutFolder | Out-Null }
$outPath = Join-Path $OutFolder "$Name.ipt"
$doc.SaveAs($outPath, $false)
Write-Host "Saved: $outPath" -ForegroundColor Cyan

# ---- STEP/STL export (use Document.SaveAs — Inventor auto-detects format from extension) ----
if ($ExportSTEP) {
    try {
        $stepPath = Join-Path $OutFolder "$Name.step"
        $doc.SaveAs($stepPath, $true)  # $true = save copy (don't change open doc)
        Write-Host "Saved STEP: $stepPath ($(([Math]::Round((Get-Item $stepPath).Length/1KB))) KB)" -ForegroundColor Cyan
    } catch {
        Write-Host "STEP export failed: $_" -ForegroundColor DarkYellow
    }
}

if ($ExportSTL) {
    try {
        $stlPath = Join-Path $OutFolder "$Name.stl"
        $doc.SaveAs($stlPath, $true)
        Write-Host "Saved STL: $stlPath ($(([Math]::Round((Get-Item $stlPath).Length/1KB))) KB)" -ForegroundColor Cyan
    } catch {
        Write-Host "STL export failed: $_" -ForegroundColor DarkYellow
    }
}

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
