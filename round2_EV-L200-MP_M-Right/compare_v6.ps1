$ErrorActionPreference = 'Stop'
$myV6 = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt_v6.ipt"
$realF = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real.ipt"
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') } catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }
$tg = $inv.TransientGeometry

function RenderAt($file, $img, $eye) {
    $doc = $inv.Documents.Open($file, $true)
    Start-Sleep 1
    $cam = $inv.ActiveView.Camera
    $cam.Eye    = $tg.CreatePoint($eye[0], $eye[1], $eye[2])
    $cam.Target = $tg.CreatePoint(0, 0, 0)
    $cam.UpVector = $tg.CreateUnitVector(0, 0, 1)
    $cam.ApplyWithoutTransition()
    $inv.ActiveView.Fit()
    Start-Sleep -Milliseconds 800
    $inv.ActiveView.SaveAsBitmap($img, 800, 800)
    $doc.Close($false)
}

$base = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right"
RenderAt $myV6  "$base\v6_ISO_NE.png"  @(70, -70, 70)
RenderAt $realF "$base\real_ISO_NE2.png" @(70, -70, 70)
RenderAt $myV6  "$base\v6_ISO_SW.png"  @(-70, 70, 70)
RenderAt $realF "$base\real_ISO_SW2.png" @(-70, 70, 70)
Write-Host "All saved"
