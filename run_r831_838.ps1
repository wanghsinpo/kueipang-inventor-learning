$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round831_punch-middle-6-mobile-155648',
    'round832_punch-selfrivet-115712',
    'round833_punch-79872',
    'round834_punch-3003-77824',
    'round835_punch-1803-83456',
    'round836_punch-1803b-87552',
    'round837_punch-3003b-80384',
    'round838_rotor-magcore-53x25-165376'
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
