$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round647_stator-90x47-single-756736',
    'round648_stator-90x47-755712',
    'round649_stator-121x60-s24-inner4-824832',
    'round650_stator-121x60-s24-inner4-gnd-770560',
    'round651_stator-121x60-s24-bottom-gnd-666112',
    'round652_stator-121x60-s24-bottom-670720',
    'round653_rotor-60x30-r18-t12-271360',
    'round654_rotor-121x60-integrated-611840'
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
Write-Host "All done."
