$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round719_rotor-magcore-cover-206336',
    'round720_rotor-magcore-kbv3-258560',
    'round721_rotor-magcore-whitecov03-201728',
    'round722_rotor-magcore-magnet-91136',
    'round723_stator-160x80-s24v6-620032',
    'round724_stator-160x80-s24v3-705536',
    'round725_rotor-160x80-r34-296448',
    'round726_stator-164x80-s24-385536'
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
