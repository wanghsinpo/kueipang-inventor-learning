$ErrorActionPreference = 'Stop'
$f = "$env:USERPROFILE\Desktop\test\round23_KE-BH-026_AA_BP-M\real.ipt"
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }
$doc = $inv.Documents.Open($f, $true)
$cd = $doc.ComponentDefinition; $body = $cd.SurfaceBodies.Item(1)
$rb = $body.RangeBox
"BBox: {0:F2} x {1:F2} x {2:F2}" -f (($rb.MaxPoint.X-$rb.MinPoint.X)*10),(($rb.MaxPoint.Y-$rb.MinPoint.Y)*10),(($rb.MaxPoint.Z-$rb.MinPoint.Z)*10)
"Vol: {0:F1}" -f ($cd.MassProperties.Volume * 1000)
$radii = @{}
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5891) { continue }
    $r = [Math]::Round($f.Geometry.Radius * 10, 2)
    if (-not $radii.ContainsKey($r)) { $radii[$r]=0 }
    $radii[$r]++
}
"Cylinders by R:"
foreach ($k in $radii.Keys | Sort-Object -Descending) { "  R={0}: {1}" -f $k,$radii[$k] }
"Features: $($cd.Features.Count)"
foreach ($fe in $cd.Features) { "  - $($fe.Name)" }
