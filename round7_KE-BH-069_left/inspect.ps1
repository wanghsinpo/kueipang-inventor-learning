$ErrorActionPreference = 'Stop'
$f = "$env:USERPROFILE\Desktop\test\round7_KE-BH-069_left\real.ipt"
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }
$doc = $inv.Documents.Open($f, $true)
$cd = $doc.ComponentDefinition; $body = $cd.SurfaceBodies.Item(1)
$rb = $body.RangeBox
"BBox X=[{0:F2},{1:F2}] len={2:F2}" -f ($rb.MinPoint.X*10),($rb.MaxPoint.X*10),(($rb.MaxPoint.X-$rb.MinPoint.X)*10)
"BBox Y=[{0:F2},{1:F2}] len={2:F2}" -f ($rb.MinPoint.Y*10),($rb.MaxPoint.Y*10),(($rb.MaxPoint.Y-$rb.MinPoint.Y)*10)
"BBox Z=[{0:F2},{1:F2}] len={2:F2}" -f ($rb.MinPoint.Z*10),($rb.MaxPoint.Z*10),(($rb.MaxPoint.Z-$rb.MinPoint.Z)*10)
$mp = $cd.MassProperties
"Volume: {0:F1} mm^3" -f ($mp.Volume * 1000)
"Surface Area: {0:F1} mm^2" -f ($mp.Area * 100)
"`nCylindrical faces:"
foreach ($fa in $body.Faces) {
    if ($fa.SurfaceType -ne 5891) { continue }
    $g = $fa.Geometry
    "  R={0:F3} | base=({1:F2},{2:F2},{3:F2}) | axis=({4:F2},{5:F2},{6:F2}) | area={7:F1}" -f ($g.Radius*10),($g.BasePoint.X*10),($g.BasePoint.Y*10),($g.BasePoint.Z*10),$g.AxisVector.X,$g.AxisVector.Y,$g.AxisVector.Z,($fa.Evaluator.Area*100)
}
"`nPlanar faces:"
foreach ($fa in $body.Faces) {
    if ($fa.SurfaceType -ne 5890) { continue }
    $g = $fa.Geometry
    "  root=({0:F2},{1:F2},{2:F2}) | n=({3:F2},{4:F2},{5:F2}) | area={6:F1}" -f ($g.RootPoint.X*10),($g.RootPoint.Y*10),($g.RootPoint.Z*10),$g.Normal.X,$g.Normal.Y,$g.Normal.Z,($fa.Evaluator.Area*100)
}
"`nFeatures:"
foreach ($fe in $cd.Features) { "  - {0} (type {1})" -f $fe.Name,$fe.Type }
