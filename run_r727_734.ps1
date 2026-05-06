$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round727_rotor-160x80-r28x42-334848',
    'round728_rotor-160x80-r28x32-336384',
    'round729_rotor-164x80-r34-392192',
    'round730_rotor-121x60-80s-606208',
    'round731_rotor-160x80x130-r28-309760',
    'round732_rotor-160x80-r28v1-297984',
    'round733_stator-128x80-s36s-596480',
    'round734_stator-128x80-s36-504320'
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
