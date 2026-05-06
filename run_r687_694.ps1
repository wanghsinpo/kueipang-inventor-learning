$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round687_stator-140x90-s36-419840',
    'round688_stator-140x90-s24b-370176',
    'round689_stator-140x90-s24-463872',
    'round690_rotor-140x90-r34-477184',
    'round691_stator-90x48-s24-453120',
    'round692_stator-90x48-s24-outer4-485376',
    'round693_rotor-90x48-r34-311296',
    'round694_rotor-90x48-r17-215040'
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
