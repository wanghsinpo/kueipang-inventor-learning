$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round679_rotor-117x60-r30-t70-178688',
    'round680_rotor-117x60-r30-199168',
    'round681_rotor-117x60-r30-194048',
    'round682_rotor-117x60-r30-198144',
    'round683_rotor-90x47-r11-347648',
    'round684_stator-90x47-50s-664064',
    'round685_stator-90x47-45s-outer2-491008',
    'round686_stator-90x48-2073600'
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
