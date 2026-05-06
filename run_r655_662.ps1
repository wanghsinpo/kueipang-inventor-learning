$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round655_stator-90x47-2013-733184',
    'round656_stator-90x47-u1-493056',
    'round657_rotor-90x47-r8-344064',
    'round658_rotor-90x47-r14-346624',
    'round659_rotor-90x47-t25-306176',
    'round660_stator-121x60-s24-bottom-gnd2-705024',
    'round661_stator-121x60-s24-inner4-gnd2-764928',
    'round662_rotor-60x30-r18-t90-248320'
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
