$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round783_stator-92x52-s18-402432',
    'round784_stator-90x51-s18-299520',
    'round785_stator-90x50-s18-496128',
    'round786_stator-110x59-s18-435200',
    'round787_stator-110x64-s18-354816',
    'round788_stator-90x48-s18-2157056',
    'round789_rotor-121x60-r30-523264',
    'round790_rotor-121x60-r30v5-553472'
)
foreach ($r in $rounds) {
    Get-Process -Name "Inventor" -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    $folder = Join-Path $desk $r
    Write-Host "=== $r ==="
    $out = powershell -ExecutionPolicy Bypass -File auto_ring_v3.ps1 -folder $folder 2>&1
    $out | Select-String -Pattern "BACKCALC|REAL:|My:|diff|SKIP|ERROR|BBox|Vol|ArgumentException" | Select-Object -Last 8
    Write-Host "---"
}
Get-Process -Name "Inventor" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "=== ALL DONE ==="
