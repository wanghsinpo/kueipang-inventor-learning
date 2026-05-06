$desk = Join-Path $env:USERPROFILE 'Desktop\test'
$base = Join-Path $env:USERPROFILE '.claude\projects\C--Users----Desktop-test\fc6835c2-f8f6-4f26-b809-53a234e8a02c\tool-results'
$files = @(
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073535246.txt'; name='round727_rotor-160x80-r28x42-334848' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073540239.txt'; name='round728_rotor-160x80-r28x32-336384' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073548686.txt'; name='round729_rotor-164x80-r34-392192' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073554285.txt'; name='round730_rotor-121x60-80s-606208' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073565339.txt'; name='round731_rotor-160x80x130-r28-309760' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073569795.txt'; name='round732_rotor-160x80-r28v1-297984' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073580086.txt'; name='round733_stator-128x80-s36s-596480' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073585734.txt'; name='round734_stator-128x80-s36-504320' }
)
foreach ($f in $files) {
    $srcPath = Join-Path $base $f.src
    $dstDir = Join-Path $desk $f.name
    $dstPath = Join-Path $dstDir 'real.ipt'
    if (-not (Test-Path $dstDir)) { md $dstDir | Out-Null }
    $raw = [System.IO.File]::ReadAllText($srcPath, [System.Text.Encoding]::UTF8)
    $json = $raw | ConvertFrom-Json
    if ($json.content -is [string]) { $b64 = $json.content } else { $b64 = $json.content[0].embeddedResource.contents.blob }
    $bytes = [Convert]::FromBase64String($b64)
    [IO.File]::WriteAllBytes($dstPath, $bytes)
    Write-Host ('Written: ' + $f.name + ' = ' + $bytes.Length + ' bytes')
}
