$ErrorActionPreference = 'Stop'
$realF = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real.ipt"

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }

$tg = $inv.TransientGeometry
$doc = $inv.Documents.Open($realF, $true)
Start-Sleep 2

function SetCam($eye, $target, $up, $imgPath, $label) {
    $cam = $inv.ActiveView.Camera
    $cam.Eye    = $tg.CreatePoint($eye[0], $eye[1], $eye[2])
    $cam.Target = $tg.CreatePoint($target[0], $target[1], $target[2])
    $cam.UpVector = $tg.CreateUnitVector($up[0], $up[1], $up[2])
    $cam.ApplyWithoutTransition()
    $inv.ActiveView.Fit()
    Start-Sleep -Milliseconds 800
    $inv.ActiveView.SaveAsBitmap($imgPath, 800, 800)
    Write-Host "  $label : $imgPath" -ForegroundColor Green
}

$base = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right"

# BOTTOM view: looking UP from below (eye at -Z, target origin, up=+Y)
SetCam @(0, 0, -100) @(0, 0, 0) @(0, 1, 0) "$base\real_BOTTOM.png" "BOTTOM"

# BACK view: looking from -Y toward +Y (camera at -Y), shows +Y face of part
SetCam @(0, 100, 0) @(0, 0, 0) @(0, 0, 1) "$base\real_BACK.png" "BACK"

# Two opposite ISOs
SetCam @(70, 70, 70) @(0, 0, 0) @(0, 0, 1) "$base\real_ISO_NE.png" "ISO_NE"
SetCam @(-70, -70, 70) @(0, 0, 0) @(0, 0, 1) "$base\real_ISO_SW.png" "ISO_SW"
