$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round759_stator-140x90-s36-419840',
    'round760_stator-140x90-s36v8-471552',
    'round761_stator-136x81-s36-495616',
    'round762_stator-121x71-s36std-604672',
    'round763_stator-121x71-s36inner4-627200',
    'round764_stator-121x71-s36outer2-633856',
    'round765_stator-121x71-s36combo-638976',
    'round766_rotor-121x71-s36std-472576'
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
