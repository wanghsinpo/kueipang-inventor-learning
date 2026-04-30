$ErrorActionPreference = 'Stop'
$myFile   = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt.ipt"
$realFile = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real.ipt"

try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
} catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application'))
    Start-Sleep 2
}
$inv.Visible = $true

try { $inv.Documents.CloseAll($false) } catch { }
$myDoc = $inv.Documents.Open($myFile, $true)
$realDoc = $inv.Documents.Open($realFile, $true)

function Show($doc, $label) {
    Write-Host "`n=== $label ===" -ForegroundColor Yellow
    $cd = $doc.ComponentDefinition
    $body = $cd.SurfaceBodies.Item(1)
    $mp = $cd.MassProperties
    $rb = $body.RangeBox
    $xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
    $yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
    $zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
    $vol = [Math]::Round($mp.Volume * 1000, 1)
    $area = [Math]::Round($mp.Area * 100, 1)
    Write-Host ("BBox (mm): {0} x {1} x {2}" -f $xL, $yL, $zL)
    Write-Host ("Volume:    {0} mm^3" -f $vol)
    Write-Host ("Area:      {0} mm^2" -f $area)
    Write-Host ("Faces/Edges: {0}/{1}" -f $body.Faces.Count, $body.Edges.Count)
    Write-Host ("Features ({0}):" -f $cd.Features.Count)
    foreach ($f in $cd.Features) {
        Write-Host ("  - {0} (type {1})" -f $f.Name, $f.Type)
    }
    return [PSCustomObject]@{
        BBox = "$xL x $yL x $zL"; XL=$xL; YL=$yL; ZL=$zL
        Vol=$vol; Area=$area; Faces=$body.Faces.Count; Edges=$body.Edges.Count
        FeatureCount=$cd.Features.Count
    }
}

$my   = Show $myDoc   "MY attempt (from PDF)"
$real = Show $realDoc "REAL .ipt"

Write-Host "`n=== DIFF ===" -ForegroundColor Magenta
Write-Host ("BBox       my={0} real={1}" -f $my.BBox, $real.BBox)
Write-Host ("Volume     my={0} real={1} delta_pct={2:F1}%" -f $my.Vol, $real.Vol, ((($my.Vol - $real.Vol) / $real.Vol) * 100))
Write-Host ("Area       my={0} real={1} delta_pct={2:F1}%" -f $my.Area, $real.Area, ((($my.Area - $real.Area) / $real.Area) * 100))
Write-Host ("Faces      my={0} real={1}" -f $my.Faces, $real.Faces)
Write-Host ("Edges      my={0} real={1}" -f $my.Edges, $real.Edges)
Write-Host ("Features   my={0} real={1}" -f $my.FeatureCount, $real.FeatureCount)
