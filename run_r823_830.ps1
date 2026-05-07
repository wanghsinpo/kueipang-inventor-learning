$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round823_punch-upper-general-174080',
    'round824_punch-160x80-shoulder-96256',
    'round825_punch-outer-fixblock-122880',
    'round826_punch-outer-2hole-fixplate-149504',
    'round827_punch-upper-general-0001-174592',
    'round828_punch-middle-2-tail5mm-157184',
    'round829_punch-middle-2-tail5mm-0001-157696',
    'round830_punch-middle-6-mobile-0001-155136'
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
