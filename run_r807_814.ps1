$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round807_ring-oring-disk-156672',
    'round808_ring-oring-vacuum-150016',
    'round809_rotor-140x90-r48-823808',
    'round810_rotor-140x90-r48v8-820736',
    'round811_rotor-140x90-r48old-911872',
    'round812_rotor-90x48-r34-311296',
    'round813_rotor-90x48-r17-215040',
    'round814_punch-94x53-118784'
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
