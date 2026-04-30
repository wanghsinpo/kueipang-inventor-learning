$ErrorActionPreference = 'Stop'
$f = "$env:USERPROFILE\Desktop\test\round8_KE-BH-071_X200N\real.ipt"
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }
$doc = $inv.Documents.Open($f, $true)
$cd = $doc.ComponentDefinition; $body = $cd.SurfaceBodies.Item(1)
$rb = $body.RangeBox
"BBox: {0:F2} x {1:F2} x {2:F2}" -f (($rb.MaxPoint.X-$rb.MinPoint.X)*10),(($rb.MaxPoint.Y-$rb.MinPoint.Y)*10),(($rb.MaxPoint.Z-$rb.MinPoint.Z)*10)
$mp = $cd.MassProperties
"Vol: {0:F1} mm^3" -f ($mp.Volume * 1000)
"Cyls:"
foreach ($fa in $body.Faces) {
    if ($fa.SurfaceType -ne 5891) { continue }
    $g = $fa.Geometry
    "  R={0:F2} | base=({1:F1},{2:F1},{3:F1}) | axis Z={4:F1} | h_eff={5:F2}" -f ($g.Radius*10),($g.BasePoint.X*10),($g.BasePoint.Y*10),($g.BasePoint.Z*10),$g.AxisVector.Z,(($fa.Evaluator.Area*100)/(2*[Math]::PI*$g.Radius*10))
}
"`nKey planes (by Z + diagonal):"
foreach ($fa in $body.Faces) {
    if ($fa.SurfaceType -ne 5890) { continue }
    $g = $fa.Geometry
    if ([Math]::Abs($g.Normal.X) -gt 0.5 -or [Math]::Abs($g.Normal.Y) -gt 0.5 -or [Math]::Abs($g.Normal.Z) -gt 0.99) {
        "  root=({0:F1},{1:F1},{2:F1}) | n=({3:F2},{4:F2},{5:F2}) | A={6:F1}" -f ($g.RootPoint.X*10),($g.RootPoint.Y*10),($g.RootPoint.Z*10),$g.Normal.X,$g.Normal.Y,$g.Normal.Z,($fa.Evaluator.Area*100)
    }
}
"`nFeatures: $($cd.Features.Count)"
foreach ($fe in $cd.Features) { "  - $($fe.Name)" }
