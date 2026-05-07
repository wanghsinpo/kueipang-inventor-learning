$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round839_rotor-magcore-42x20-168448',
    'round840_rotor-94x53-r22-0006-294912',
    'round841_rotor-94x53-r22-293376',
    'round842_rotor-magcore-largeweld-232448',
    'round843_rotor-magcore-largeweld1-291840',
    'round844_rotor-2021magcore-cover0008-225792',
    'round845_rotor-2021magcore-cover-203264',
    'round846_rotor-121x72-r48-20-223744'
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
