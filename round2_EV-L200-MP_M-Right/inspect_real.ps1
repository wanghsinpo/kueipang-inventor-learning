## inspect_real.ps1 — dump exact geometry from real bearing seat
$ErrorActionPreference = 'Stop'
$realFile = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real.ipt"

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }

$doc = $inv.Documents.Open($realFile, $true)
$cd = $doc.ComponentDefinition
$body = $cd.SurfaceBodies.Item(1)

Write-Host "===== BBox =====" -ForegroundColor Yellow
$rb = $body.RangeBox
"X: [{0:F2}, {1:F2}] mm   len={2:F2}" -f ($rb.MinPoint.X*10), ($rb.MaxPoint.X*10), (($rb.MaxPoint.X - $rb.MinPoint.X)*10) | Write-Host
"Y: [{0:F2}, {1:F2}] mm   len={2:F2}" -f ($rb.MinPoint.Y*10), ($rb.MaxPoint.Y*10), (($rb.MaxPoint.Y - $rb.MinPoint.Y)*10) | Write-Host
"Z: [{0:F2}, {1:F2}] mm   len={2:F2}" -f ($rb.MinPoint.Z*10), ($rb.MaxPoint.Z*10), (($rb.MaxPoint.Z - $rb.MinPoint.Z)*10) | Write-Host

Write-Host "`n===== All Faces by SurfaceType =====" -ForegroundColor Yellow
# SurfaceTypeEnum: kPlaneSurface=5890, kCylinderSurface=5891, kConeSurface=5892, etc.
$counts = @{}
foreach ($f in $body.Faces) {
    $st = $f.SurfaceType
    if (-not $counts.ContainsKey($st)) { $counts[$st] = 0 }
    $counts[$st]++
}
foreach ($k in $counts.Keys | Sort-Object) {
    "  Type {0}: {1} face(s)" -f $k, $counts[$k] | Write-Host
}

Write-Host "`n===== Cylindrical Faces (radius + axis info) =====" -ForegroundColor Yellow
$i = 0
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5891) { continue }   # kCylinderSurface
    $g = $f.Geometry  # Cylinder
    # Cylinder has: BasePoint, AxisVector, Radius
    $r = $g.Radius * 10
    $bp = $g.BasePoint
    $av = $g.AxisVector
    $area = 0
    try { $area = $f.Evaluator.Area } catch { }
    "  Cyl[{0}] R={1:F3} mm | base=({2:F2},{3:F2},{4:F2}) | axis=({5:F2},{6:F2},{7:F2}) | area={8:F1}" -f $i, $r, ($bp.X*10), ($bp.Y*10), ($bp.Z*10), $av.X, $av.Y, $av.Z, ($area*100) | Write-Host
    $i++
}

Write-Host "`n===== Planar Faces (Z position + normal + outer area) =====" -ForegroundColor Yellow
$i = 0
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5890) { continue }   # kPlaneSurface
    $g = $f.Geometry  # Plane
    $rp = $g.RootPoint
    $n = $g.Normal
    $area = 0
    try { $area = $f.Evaluator.Area } catch { }
    "  Plane[{0}] root=({1:F2},{2:F2},{3:F2}) | normal=({4:F2},{5:F2},{6:F2}) | area={7:F1}" -f $i, ($rp.X*10), ($rp.Y*10), ($rp.Z*10), $n.X, $n.Y, $n.Z, ($area*100) | Write-Host
    $i++
}

Write-Host "`n===== Edges (count by curve type) =====" -ForegroundColor Yellow
$ec = @{}
foreach ($e in $body.Edges) {
    $gt = $e.GeometryType
    if (-not $ec.ContainsKey($gt)) { $ec[$gt] = 0 }
    $ec[$gt]++
}
foreach ($k in $ec.Keys | Sort-Object) { "  Type {0}: {1} edge(s)" -f $k, $ec[$k] | Write-Host }

Write-Host "`n===== Mass =====" -ForegroundColor Yellow
$mp = $cd.MassProperties
"Volume: {0:F1} mm^3" -f ($mp.Volume * 1000) | Write-Host
"Surface Area: {0:F1} mm^2" -f ($mp.Area * 100) | Write-Host

Write-Host "`n===== Features =====" -ForegroundColor Yellow
foreach ($f in $cd.Features) {
    "  - {0} (type {1})" -f $f.Name, $f.Type | Write-Host
}
