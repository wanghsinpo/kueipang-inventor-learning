## build_part.ps1
## Drives Autodesk Inventor via COM to build a bearing-housing-like part
## from photos in C:\Users\奎邦\Desktop\test
## All input dimensions in mm; Inventor API uses cm internally so we convert.

$ErrorActionPreference = 'Stop'

function MM($v) { return [double]$v / 10.0 }   # mm -> cm

# ---------- Inventor enums (integer values) ----------
$kPartDocumentObject       = 12290
$kJoinOperation            = 20481
$kCutOperation             = 20482
$kPositiveExtentDirection  = 20993
$kNegativeExtentDirection  = 20994
$kPlaneSurface             = 5890
$kMetricSystemOfMeasure    = 11266   # for GetTemplateFile

# ---------- Connect to Inventor ----------
Write-Host "Connecting to Inventor..." -ForegroundColor Cyan
$invType = [Type]::GetTypeFromProgID('Inventor.Application')
if ($null -eq $invType) { throw "Inventor.Application ProgID not registered." }

try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
    Write-Host "  Attached to running Inventor." -ForegroundColor Green
} catch {
    Write-Host "  Launching Inventor (may take 30-60s)..." -ForegroundColor Yellow
    $inv = [Activator]::CreateInstance($invType)
    $inv.Visible = $true
    Start-Sleep -Seconds 2
}
$inv.Visible = $true

# ---------- Clean state ----------
Write-Host "Closing any existing documents (without saving)..." -ForegroundColor DarkYellow
try { $inv.Documents.CloseAll($false) } catch { }

# ---------- New part ----------
Write-Host "Creating new part..." -ForegroundColor Cyan
$tpl = $inv.FileManager.GetTemplateFile($kPartDocumentObject)
$partDoc = $inv.Documents.Add($kPartDocumentObject, $tpl, $true)
$cd = $partDoc.ComponentDefinition
$tg = $inv.TransientGeometry

# ---------- Step 1: Plate outline (shield) on XY ----------
Write-Host "Step 1: Plate outline + extrude 12mm..." -ForegroundColor Cyan
# WorkPlanes: 1=YZ, 2=XZ, 3=XY
$xy = $cd.WorkPlanes.Item(3)
$s1 = $cd.Sketches.Add($xy)

$pTopL    = $tg.CreatePoint2d((MM -40), (MM   0))
$pTop     = $tg.CreatePoint2d((MM   0), (MM  40))
$pTopR    = $tg.CreatePoint2d((MM  40), (MM   0))
$pSideR   = $tg.CreatePoint2d((MM  40), (MM -25))
$pCornerR = $tg.CreatePoint2d((MM  25), (MM -40))
$pCornerL = $tg.CreatePoint2d((MM -25), (MM -40))
$pSideL   = $tg.CreatePoint2d((MM -40), (MM -25))

# Use CenterStartEnd: arc goes counterclockwise from Start to End around Center.
# We want the arc on top: start at right (40,0), go CCW up through (0,40), end at left (-40,0).
$pCenter = $tg.CreatePoint2d(0, 0)
$arc = $s1.SketchArcs.AddByCenterStartEndPoint($pCenter, $pTopR, $pTopL)
# Now arc.StartSketchPoint is at pTopR, arc.EndSketchPoint is at pTopL.
$L1 = $s1.SketchLines.AddByTwoPoints($arc.EndSketchPoint, $pSideL)        # pTopL -> pSideL
$L2 = $s1.SketchLines.AddByTwoPoints($L1.EndSketchPoint, $pCornerL)        # pSideL -> pCornerL
$L3 = $s1.SketchLines.AddByTwoPoints($L2.EndSketchPoint, $pCornerR)        # pCornerL -> pCornerR
$L4 = $s1.SketchLines.AddByTwoPoints($L3.EndSketchPoint, $pSideR)          # pCornerR -> pSideR
$null = $s1.SketchLines.AddByTwoPoints($L4.EndSketchPoint, $arc.StartSketchPoint)  # pSideR -> pTopR

Write-Host "  Sketch1 entities: arcs=$($s1.SketchArcs.Count), lines=$($s1.SketchLines.Count)" -ForegroundColor DarkGray

$prof1 = $s1.Profiles.AddForSolid()
$ed1 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof1, $kJoinOperation)
$ed1.SetDistanceExtent((MM 12), $kPositiveExtentDirection)
$plate = $cd.Features.ExtrudeFeatures.Add($ed1)

# ---------- Step 2: Boss (Ø50 x 15mm) extending in -Z ----------
Write-Host "Step 2: Boss Ø50 x 15mm..." -ForegroundColor Cyan
$s2 = $cd.Sketches.Add($xy)
$null = $s2.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 25))
$prof2 = $s2.Profiles.AddForSolid()
$ed2 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof2, $kJoinOperation)
$ed2.SetDistanceExtent((MM 15), $kNegativeExtentDirection)
$boss = $cd.Features.ExtrudeFeatures.Add($ed2)

# ---------- Step 3: Center bore Ø30 through ----------
Write-Host "Step 3: Center bore Ø30 thru..." -ForegroundColor Cyan
$s3 = $cd.Sketches.Add($xy)
$null = $s3.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 15))
$prof3 = $s3.Profiles.AddForSolid()
$ed3a = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3, $kCutOperation)
$ed3a.SetDistanceExtent((MM 50), $kPositiveExtentDirection)   # cuts up through plate
$null = $cd.Features.ExtrudeFeatures.Add($ed3a)

# Need a fresh sketch for the second direction — reuse profile by re-sketching
$s3b = $cd.Sketches.Add($xy)
$null = $s3b.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 15))
$prof3b = $s3b.Profiles.AddForSolid()
$ed3b = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof3b, $kCutOperation)
$ed3b.SetDistanceExtent((MM 50), $kNegativeExtentDirection)   # cuts down through boss
$null = $cd.Features.ExtrudeFeatures.Add($ed3b)

# ---------- Helper: find a planar face by Z coordinate and normal direction ----------
function Find-PlanarFaceAtZ($body, $zCm) {
    foreach ($f in $body.Faces) {
        if ($f.SurfaceType -ne $kPlaneSurface) { continue }
        $r = $f.Geometry.RootPoint
        # Ensure the face's normal is along Z (not a side face that happens to pass through this Z)
        $n = $f.Geometry.Normal
        if ([Math]::Abs($n.Z) -lt 0.99) { continue }
        if ([Math]::Abs($r.Z - $zCm) -lt 0.01) { return $f }
    }
    return $null
}

# ---------- Step 4: Front counterbore Ø42 x 5mm deep on Z=12 face ----------
Write-Host "Step 4: Front counterbore Ø42 x 5mm..." -ForegroundColor Cyan
$body = $partDoc.ComponentDefinition.SurfaceBodies.Item(1)
$frontFace = Find-PlanarFaceAtZ $body (MM 12) $false
if ($null -eq $frontFace) { throw "Could not find front face at Z=12mm" }
$s4 = $cd.Sketches.Add($frontFace)
$null = $s4.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM 21))
$prof4 = $s4.Profiles.AddForSolid()
$ed4 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof4, $kCutOperation)
$ed4.SetDistanceExtent((MM 5), $kNegativeExtentDirection)
$null = $cd.Features.ExtrudeFeatures.Add($ed4)

# ---------- Step 5: Two opposing slots cut from boss back face (Z=-15) ----------
Write-Host "Step 5: Two slots in boss back..." -ForegroundColor Cyan
$bossBackFace = Find-PlanarFaceAtZ $partDoc.ComponentDefinition.SurfaceBodies.Item(1) (MM -15)
if ($null -eq $bossBackFace) { throw "Could not find boss back face at Z=-15mm" }
$s5 = $cd.Sketches.Add($bossBackFace)
# Slot 1: top, centered at (0, +18), 14W x 12H
function AddRectByCenter($sketch, $cx, $cy, $w, $h) {
    $hw = $w / 2.0; $hh = $h / 2.0
    $p1 = $tg.CreatePoint2d((MM ($cx - $hw)), (MM ($cy - $hh)))
    $p2 = $tg.CreatePoint2d((MM ($cx + $hw)), (MM ($cy - $hh)))
    $p3 = $tg.CreatePoint2d((MM ($cx + $hw)), (MM ($cy + $hh)))
    $p4 = $tg.CreatePoint2d((MM ($cx - $hw)), (MM ($cy + $hh)))
    $r1 = $sketch.SketchLines.AddByTwoPoints($p1, $p2)
    $r2 = $sketch.SketchLines.AddByTwoPoints($r1.EndSketchPoint, $p3)
    $r3 = $sketch.SketchLines.AddByTwoPoints($r2.EndSketchPoint, $p4)
    $null = $sketch.SketchLines.AddByTwoPoints($r3.EndSketchPoint, $r1.StartSketchPoint)
}
# NOTE: when sketching on a face whose normal is -Z, the face's local Y might be flipped.
# We just place rectangles at ±18 in the face's local Y; if mirrored, the result is still symmetric.
AddRectByCenter $s5 0  18 14 12
AddRectByCenter $s5 0 -18 14 12
$prof5 = $s5.Profiles.AddForSolid()
$ed5 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof5, $kCutOperation)
$ed5.SetDistanceExtent((MM 7), $kNegativeExtentDirection)   # cut into the boss
$null = $cd.Features.ExtrudeFeatures.Add($ed5)

# ---------- Step 6: 4 perimeter counterbore holes ----------
Write-Host "Step 6: 4 counterbore mounting holes..." -ForegroundColor Cyan
# Re-find the front face (it has changed shape but is still at Z=12)
$frontFace2 = Find-PlanarFaceAtZ $partDoc.ComponentDefinition.SurfaceBodies.Item(1) (MM 12)
$holePositions = @(
    @( 28,  14),
    @(-28,  14),
    @( 28, -28),
    @(-28, -28)
)

# 6a — clearance Ø5.5 thru
$s6a = $cd.Sketches.Add($frontFace2)
foreach ($p in $holePositions) {
    $null = $s6a.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM $p[0]), (MM $p[1])), (MM 2.75))
}
$prof6a = $s6a.Profiles.AddForSolid()
$ed6a = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof6a, $kCutOperation)
$ed6a.SetDistanceExtent((MM 30), $kNegativeExtentDirection)   # well past plate (12mm)
$null = $cd.Features.ExtrudeFeatures.Add($ed6a)

# 6b — Ø9 counterbore depth 5 on the same face
$frontFace3 = Find-PlanarFaceAtZ $partDoc.ComponentDefinition.SurfaceBodies.Item(1) (MM 12)
$s6b = $cd.Sketches.Add($frontFace3)
foreach ($p in $holePositions) {
    $null = $s6b.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM $p[0]), (MM $p[1])), (MM 4.5))
}
$prof6b = $s6b.Profiles.AddForSolid()
$ed6b = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof6b, $kCutOperation)
$ed6b.SetDistanceExtent((MM 5), $kNegativeExtentDirection)
$null = $cd.Features.ExtrudeFeatures.Add($ed6b)

# ---------- Step 7: 2 side M4 clearance holes ----------
Write-Host "Step 7: 2 side M4-tap holes..." -ForegroundColor Cyan
$frontFace4 = Find-PlanarFaceAtZ $partDoc.ComponentDefinition.SurfaceBodies.Item(1) (MM 12)
$s7 = $cd.Sketches.Add($frontFace4)
$sidePositions = @(
    @( 33, -10),
    @(-33, -10)
)
foreach ($p in $sidePositions) {
    $null = $s7.SketchCircles.AddByCenterRadius($tg.CreatePoint2d((MM $p[0]), (MM $p[1])), (MM 2.0))
}
$prof7 = $s7.Profiles.AddForSolid()
$ed7 = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof7, $kCutOperation)
$ed7.SetDistanceExtent((MM 30), $kNegativeExtentDirection)
$null = $cd.Features.ExtrudeFeatures.Add($ed7)

# ---------- Save ----------
$outPath = Join-Path $env:USERPROFILE 'Desktop\test\bearing_housing_demo.ipt'
Write-Host "Saving to $outPath ..." -ForegroundColor Cyan
$partDoc.SaveAs($outPath, $false)

Write-Host "`nDone. File: $outPath" -ForegroundColor Green
Write-Host "Inventor window left open so you can inspect / tweak." -ForegroundColor Green
