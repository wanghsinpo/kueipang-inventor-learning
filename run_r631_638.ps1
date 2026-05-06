$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round631_stator-94x53-s24-inner2-665088',
    'round632_stator-94x53-s24-inner2-old-562688',
    'round633_stator-92x53-s48-400384',
    'round634_stator-94x53-s24-bottom-548352',
    'round635_stator-140x90-s24-463872',
    'round636_rotor-140x90-r34-80-477184',
    'round637_rotor-140x90-r34-40-476672',
    'round638_rotor-140x90-r34-30-477696'
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
Write-Host "All done R631-R638"
