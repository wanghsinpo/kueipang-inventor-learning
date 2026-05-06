$desk = Join-Path $env:USERPROFILE 'Desktop\test'
Set-Location $desk
$rounds = @(
    'round735_stator-160x80-s24v1-737792',
    'round736_stator-160x80-s24s1-733696',
    'round737_rotor-140x90-r48x17-625664',
    'round738_rotor-136x80-assm-1144832',
    'round739_rotor-160x80-r28t30-202752',
    'round740_rotor-160x80-punch1-95744',
    'round741_rotor-160x80-punch-103936',
    'round742_stator-100x53-s24inner-537600'
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
