$ErrorActionPreference = 'Stop'
$myV5 = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\my_attempt_v5.ipt"
$realF = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real.ipt"
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') } catch {
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }

$tg = $inv.TransientGeometry

function RenderBottom($file, $img) {
    $doc = $inv.Documents.Open($file, $true)
    Start-Sleep 1
    $cam = $inv.ActiveView.Camera
    # BOTTOM view: looking up from below
    $cam.Eye    = $tg.CreatePoint(0, 0, -100)
    $cam.Target = $tg.CreatePoint(0, 0, 0)
    $cam.UpVector = $tg.CreateUnitVector(0, 1, 0)
    $cam.ApplyWithoutTransition()
    $inv.ActiveView.Fit()
    Start-Sleep -Milliseconds 800
    $inv.ActiveView.SaveAsBitmap($img, 800, 800)
    Write-Host "  Saved: $img"
    $doc.Close($false)
}

$base = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right"
RenderBottom $myV5 "$base\v5_BOTTOM.png"
RenderBottom $realF "$base\real_BOTTOM2.png"
