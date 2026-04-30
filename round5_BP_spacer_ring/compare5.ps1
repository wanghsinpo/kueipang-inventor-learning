$ErrorActionPreference = 'Stop'
$myFile = "$env:USERPROFILE\Desktop\test\round5_BP_spacer_ring\my_attempt.ipt"
$realFile = "$env:USERPROFILE\Desktop\test\round5_BP_spacer_ring\real.ipt"
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
    $vol = [Math]::Round($mp.Volume * 1000, 2)
    Write-Host ("BBox: {0} x {1} x {2} | Vol: {3} | F/E: {4}/{5} | Feats: {6}" -f $xL,$yL,$zL,$vol,$body.Faces.Count,$body.Edges.Count,$cd.Features.Count)
    foreach ($f in $cd.Features) { Write-Host ("  - {0}" -f $f.Name) }
    return [PSCustomObject]@{Vol=$vol;Faces=$body.Faces.Count;Edges=$body.Edges.Count;Feats=$cd.Features.Count;XL=$xL;YL=$yL;ZL=$zL}
}
$my = Stats $myDoc "MY"; $real = Stats $realDoc "REAL"
Write-Host "`n=== DIFF ===" -ForegroundColor Magenta
Write-Host ("Vol: my={0} real={1} delta={2:F3}%" -f $my.Vol,$real.Vol,((($my.Vol-$real.Vol)/$real.Vol)*100))
Write-Host ("F/E: my={0}/{1} real={2}/{3}" -f $my.Faces,$my.Edges,$real.Faces,$real.Edges)
Write-Host ("Feats: my={0} real={1}" -f $my.Feats,$real.Feats)
