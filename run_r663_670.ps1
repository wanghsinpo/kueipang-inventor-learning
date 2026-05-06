$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round663_stator-90x47-u-588800',
    'round664_rotor-60x30-r18-t45-252416',
    'round665_rotor-60x30-r18-t20-257024',
    'round666_stator-121x60-s24-bottom-0009-667136',
    'round667_stator-121x60-s24-bottom-2018-710656',
    'round668_stator-121x60-s24-bottom-0007-760320',
    'round669_rotor-121x60-integrated-0009-616448',
    'round670_rotor-70x35-r17-t12-228864'
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
