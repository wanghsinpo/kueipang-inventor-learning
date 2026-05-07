$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round815_punch-56x35-10hole-119296',
    'round816_punch-upper-96768',
    'round817_punch-upper-0001-97792',
    'round818_punch-18top-2-100352',
    'round819_punch-18top-1-86016',
    'round820_punch-18shoulder-113152',
    'round821_punch-1006-0001-105472',
    'round822_punch-1006-103424'
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
