$ErrorActionPreference = 'Stop'
$myFile = "$env:USERPROFILE\Desktop\test\round4_BP_Flinger\my_attempt.ipt"
$realFile = "$env:USERPROFILE\Desktop\test\round4_BP_Flinger\real.ipt"
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') } catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }
$myDoc = $inv.Documents.Open($myFile, $true)
$realDoc = $inv.Documents.Open($realFile, $true)

function Stats($doc, $label) {
    Write-Host "`n=== $label ===" -ForegroundColor Yellow
    $cd = $doc.ComponentDefinition; $body = $cd.SurfaceBodies.Item(1); $mp = $cd.MassProperties; $rb = $body.RangeBox
    $xL = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 2)
    $yL = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 2)
    $zL = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 2)
    $vol = [Math]::Round($mp.Volume * 1000, 1)
    $area = [Math]::Round($mp.Area * 100, 1)
    Write-Host ("BBox: {0} x {1} x {2} | Vol: {3} | Area: {4} | F/E: {5}/{6} | Feats: {7}" -f $xL,$yL,$zL,$vol,$area,$body.Faces.Count,$body.Edges.Count,$cd.Features.Count)
    foreach ($f in $cd.Features) { Write-Host ("  - {0}" -f $f.Name) }
    return [PSCustomObject]@{Vol=$vol;Area=$area;Faces=$body.Faces.Count;Edges=$body.Edges.Count;Feats=$cd.Features.Count;XL=$xL;YL=$yL;ZL=$zL}
}
$my = Stats $myDoc "MY"; $real = Stats $realDoc "REAL"
Write-Host "`n=== DIFF ===" -ForegroundColor Magenta
Write-Host ("BBox: my={0}x{1}x{2} real={3}x{4}x{5}" -f $my.XL,$my.YL,$my.ZL,$real.XL,$real.YL,$real.ZL)
Write-Host ("Vol:  my={0} real={1} delta={2:F1}%" -f $my.Vol,$real.Vol,((($my.Vol-$real.Vol)/$real.Vol)*100))
Write-Host ("Area: my={0} real={1} delta={2:F1}%" -f $my.Area,$real.Area,((($my.Area-$real.Area)/$real.Area)*100))
Write-Host ("F/E:  my={0}/{1} real={2}/{3}" -f $my.Faces,$my.Edges,$real.Faces,$real.Edges)
Write-Host ("Feats: my={0} real={1}" -f $my.Feats,$real.Feats)
