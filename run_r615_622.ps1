$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round615_rotor-140x90-r48-45-629760',
    'round616_stator-90x48-s24-normal-old-522752',
    'round617_rotor-90x48-r34-311296',
    'round618_stator-90x48-s24-outer4-old-596992',
    'round619_rotor-117x60-r30-200192',
    'round620_stator-94x53-s24-inner2-540160',
    'round621_stator-94x53-s24-bottom-569856',
    'round622_stator-94x53-s24-bottom-609792'
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
Write-Host "All done R615-R622"
