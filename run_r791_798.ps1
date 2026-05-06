$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round791_rotor-121x60-r30v4-550400',
    'round792_rotor-121x60x55-r30-424960',
    'round793_rotor-121x60-r30single-84480',
    'round794_rotor-117x60-r30t22v2-220160',
    'round795_rotor-117x60-r30t22-226816',
    'round796_rotor-117x60-r30-201216',
    'round797_rotor-117x60-r30alt-217600',
    'round798_rotor-90x60-r30v1-128512'
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
