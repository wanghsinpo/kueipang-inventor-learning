$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round599_stator-121x71-s36-inner4-627200',
    'round600_stator-121x72-s36-bottom-698880',
    'round601_rotor-185x90-r36-404480',
    'round602_stator-70x35-s12-433664',
    'round603_stator-70x35-s12old-433152',
    'round604_stator-70x35-s12-bottom-374272',
    'round605_stator-70x35-s12-bottomold-374784',
    'round606_stator-70x35-s12-guide-475136'
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
Write-Host "All done R599-R606"
