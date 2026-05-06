$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round607_stator-90x48-s24-normal-453120',
    'round608_stator-90x48-s24-outer4-485376',
    'round609_stator-117x60-s24-661504',
    'round610_stator-160x80-s24-470016',
    'round611_rotor-140x90-r48-80-634368',
    'round612_rotor-140x90-r48-o21-624640',
    'round613_rotor-140x90-r48-60-628736',
    'round614_rotor-140x90-r48-820736'
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
Write-Host "All done R607-R614"
