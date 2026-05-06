$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round695_rotor-140x90-r34-t30-477696',
    'round696_rotor-140x90-r34-t40-476672',
    'round697_stator-140x90-s36-471552',
    'round698_stator-90x48-s24-522752',
    'round699_stator-90x48-s24-outer4-596992',
    'round700_rotor-90x48-r17-214528',
    'round701_stator-90x48-s30-3390464',
    'round702_rotor-121x72-r48-226816'
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
