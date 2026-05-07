$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round851_jig-sisuteel-od-172544',
    'round852_sisuteel-singledip-218112',
    'round853_sisuteel-singledip0004-222208',
    'round854_sisuteel-singledip0003-218624',
    'round855_sisuteel-224768',
    'round856_sisuteel-doubledip0001-219136',
    'round857_sisuteel-singleblock0001-236544',
    'round858_sisuteel-singleblock-256000'
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
