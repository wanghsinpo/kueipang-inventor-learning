$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round671_rotor-90x60-r30-217088',
    'round672_stator-90x47-60s-663040',
    'round673_stator-117x60-s24-inner4-bottom-672768',
    'round674_stator-117x60-s24-inner4-730112',
    'round675_stator-117x60-s24-bottom-0003-614400',
    'round676_stator-117x60-s24-0004-664576',
    'round677_rotor-121x60-r30-t90-423424',
    'round678_stator-117x60-1317376'
)
foreach ($r in $rounds) {
    Get-Process -Name "Inventor" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    $folder = Join-Path $desk $r
    Write-Host "=== $r ==="
    $out = powershell -ExecutionPolicy Bypass -File auto_ring_v3.ps1 -folder $folder 2>&1
    $out | Select-String -Pattern "BACKCALC|REAL:|My:|diff|SKIP|ERROR|BBox" | Select-Object -Last 5
    Write-Host "---"
}
Get-Process -Name "Inventor" -ErrorAction SilentlyContinue | Stop-Process -Force
