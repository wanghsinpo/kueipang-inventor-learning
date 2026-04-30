$ErrorActionPreference = 'Stop'
$f = "$env:USERPROFILE\Desktop\test\round12_R1_redo_MP_Flinger\real.ipt"
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }
$doc = $inv.Documents.Open($f, $true)
$cd = $doc.ComponentDefinition; $body = $cd.SurfaceBodies.Item(1)
$rb = $body.RangeBox
"BBox: {0:F2} x {1:F2} x {2:F2}" -f (($rb.MaxPoint.X-$rb.MinPoint.X)*10),(($rb.MaxPoint.Y-$rb.MinPoint.Y)*10),(($rb.MaxPoint.Z-$rb.MinPoint.Z)*10)
"Vol: {0:F1}" -f ($cd.MassProperties.Volume * 1000)
"Cyls (sorted by R):"
$cyls = @()
foreach ($f in $body.Faces) {
    if ($f.SurfaceType -ne 5891) { continue }
    $cyls += [PSCustomObject]@{R = [Math]::Round($f.Geometry.Radius * 10, 2); BZ = [Math]::Round($f.Geometry.BasePoint.Z * 10, 2); AxZ = $f.Geometry.AxisVector.Z; H = ($f.Evaluator.Area*100)/(2*[Math]::PI*$f.Geometry.Radius*10)}
}
foreach ($c in ($cyls | Sort-Object R -Descending)) {
    "  R={0} | BZ={1} | axisZ={2:F1} | h={3:F2}" -f $c.R, $c.BZ, $c.AxZ, $c.H
}
"Features: $($cd.Features.Count)"
foreach ($fe in $cd.Features) { "  - $($fe.Name)" }
