## multi_view.ps1 — render real.ipt from 4 views to see geometry clearly
$ErrorActionPreference = 'Stop'
$realF = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right\real.ipt"

try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
try { $inv.Documents.CloseAll($false) } catch { }

$doc = $inv.Documents.Open($realF, $true)
Start-Sleep 2

$tg = $inv.TransientGeometry
$cam = $inv.ActiveView.Camera

function SetView($eye, $target, $up, $imgPath, $label) {
    $cam.Eye    = $tg.CreatePoint($eye[0], $eye[1], $eye[2])
    $cam.Target = $tg.CreatePoint($target[0], $target[1], $target[2])
    $cam.UpVector = $tg.CreateUnitVector($up[0], $up[1], $up[2])
    $cam.ApplyWithoutTransition()
    $inv.ActiveView.Fit()
    Start-Sleep -Milliseconds 800
    $inv.ActiveView.SaveAsBitmap($imgPath, 800, 800)
    Write-Host "  $label saved: $imgPath" -ForegroundColor Green
}

$base = "$env:USERPROFILE\Desktop\test\round2_EV-L200-MP_M-Right"

# Top view: looking down -Z, up=+Y
SetView @(0, 0, 100) @(0, 0, 0) @(0, 1, 0) "$base\real_TOP.png" "TOP"

# Front view: looking +Y direction, up=+Z
SetView @(0, -100, 0) @(0, 0, 0) @(0, 0, 1) "$base\real_FRONT.png" "FRONT"

# Side (right) view: looking from +X side, up=+Z
SetView @(100, 0, 0) @(0, 0, 0) @(0, 0, 1) "$base\real_RIGHT.png" "RIGHT"

# Iso view (NE upper)
SetView @(70, -70, 70) @(0, 0, 0) @(0, 0, 1) "$base\real_ISO.png" "ISO"

Write-Host "Done" -ForegroundColor Green
