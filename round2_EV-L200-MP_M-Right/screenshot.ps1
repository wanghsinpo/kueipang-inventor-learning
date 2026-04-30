## screenshot.ps1 — render iso views of my_attempt_v2 and real, side by side
$ErrorActionPreference = 'Stop'
$myV2 = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt_v4.ipt"
$realF = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real.ipt"

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }

function Render-Iso($file, $outImg) {
    $doc = $inv.Documents.Open($file, $true)
    Start-Sleep -Milliseconds 1500
    try {
        $inv.ActiveView.Fit()
    } catch { }
    Start-Sleep -Milliseconds 500
    $inv.ActiveView.SaveAsBitmap($outImg, 800, 800)
    Write-Host "  Saved: $outImg"
    return $doc
}

$myImg = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_v4_iso.png"
$realImg = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real_iso.png"

Write-Host "Rendering MY v2..." -ForegroundColor Cyan
$myDoc = Render-Iso $myV2 $myImg
$myDoc.Close($false)

Write-Host "Rendering REAL..." -ForegroundColor Cyan
$realDoc = Render-Iso $realF $realImg
$realDoc.Close($false)

Write-Host "Done. Compare:" -ForegroundColor Green
Write-Host "  MY:   $myImg"
Write-Host "  REAL: $realImg"
