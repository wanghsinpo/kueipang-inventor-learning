$ErrorActionPreference = 'Stop'
$f = "$env:USERPROFILE\Desktop\test\round9_KE-SP-018_big_spacer\real.ipt"
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
    "  R={0:F2} | base=({1:F1},{2:F1},{3:F1}) | axis Z={4:F1} | h={5:F2}" -f ($g.Radius*10),($g.BasePoint.X*10),($g.BasePoint.Y*10),($g.BasePoint.Z*10),$g.AxisVector.Z,(($fa.Evaluator.Area*100)/(2*[Math]::PI*$g.Radius*10))
}
"Features: $($cd.Features.Count)"
foreach ($fe in $cd.Features) { "  - $($fe.Name)" }
