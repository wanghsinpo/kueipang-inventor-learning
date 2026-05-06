$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round767_stator-90x60-s36-1306112',
    'round768_stator-90x60-s36v2-808448',
    'round769_stator-121x72-s36rot3-791552',
    'round770_rotor-73x-146944',
    'round771_rotor-73x-141312',
    'round772_rotor-135x73-455168',
    'round773_stator-135x73-304128',
    'round774_135x73-728576'
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
