$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round711_rotor-42x20-v8-244224',
    'round712_rotor-42x20-v7-227328',
    'round713_rotor-magweld-232448',
    'round714_stator-123x57-s24-584704',
    'round715_stator-123x57-s24-bot-527360',
    'round716_rotor-123x57-r29-429568',
    'round717_rotor-magcore-v20-183296',
    'round718_rotor-magcore-pin-238080'
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
