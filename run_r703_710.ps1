$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round703_stator-164x80-753664',
    'round704_rotor-160x80-949248',
    'round705_stator-90x47-3182592',
    'round706_stator-90x48-s24-outer4-592896',
    'round707_stator-90x48-s18-2157056',
    'round708_stator-90x53-2836480',
    'round709_rotor-60x30-r18-10158592',
    'round710_stator-185x90-778752'
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
