$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round751_rotor-single-338944',
    'round752_rotor-precut-163840',
    'round753_stator-100x53-s24inner1-444416',
    'round754_stator-100x53-s24-556032',
    'round755_stator-100x53-s24bot-484352',
    'round756_rotor-100x53-r21t75-242176',
    'round757_stator-121x72-s36-641024',
    'round758_stator-121x72-s36bot-698880'
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
