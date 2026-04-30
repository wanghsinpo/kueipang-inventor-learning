## Render TOP view of v4 alongside real for outline comparison
$ErrorActionPreference = 'Stop'
$myV4 = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt_v4.ipt"
$realF = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real.ipt"

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }

$tg = $inv.TransientGeometry

function RenderTop($file, $img) {
    $doc = $inv.Documents.Open($file, $true)
    Start-Sleep 1
    $cam = $inv.ActiveView.Camera
    $cam.Eye    = $tg.CreatePoint(0, 0, 100)
    $cam.Target = $tg.CreatePoint(0, 0, 0)
    $cam.UpVector = $tg.CreateUnitVector(0, 1, 0)
    $cam.ApplyWithoutTransition()
    $inv.ActiveView.Fit()
    Start-Sleep -Milliseconds 800
    $inv.ActiveView.SaveAsBitmap($img, 800, 800)
    Write-Host "  Saved: $img"
    $doc.Close($false)
}

RenderTop $myV4  "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\v4_TOP.png"
RenderTop $realF "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real_TOP_again.png"
