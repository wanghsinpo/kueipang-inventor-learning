$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round743_stator-single-normal-386048',
    'round744_stator-single-487936',
    'round745_stator-single03-517632',
    'round746_stator-rijiu03-406016',
    'round747_stator-rijiu-408576',
    'round748_stator-04818-17l-581120',
    'round749_stator-117x60-s24bot-619520',
    'round750_stator-121x60-s24inner06-759808'
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
