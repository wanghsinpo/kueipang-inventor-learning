$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round591_stator-121x72-s36-rotation-641024',
    'round592_stator-121x72-s36-rotation-v3-791552',
    'round593_stator-90x60-s36-1306112',
    'round594_stator-90x60-s36-v2-808448',
    'round595_stator-121x71-s36-outer2-633856',
    'round596_rotor-121x71-s36-std-472576',
    'round597_stator-121x71-s36-combo-638976',
    'round598_stator-121x71-s36-std-604672'
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
Write-Host "All done R591-R598"
