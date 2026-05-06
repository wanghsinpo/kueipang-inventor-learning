$desk = Join-Path $env:USERPROFILE 'Desktop\test'
$base = Join-Path $env:USERPROFILE '.claude\projects\C--Users----Desktop-test\fc6835c2-f8f6-4f26-b809-53a234e8a02c\tool-results'
$files = @(
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778075482461.txt'; name='round767_stator-90x60-s36-1306112' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778075488617.txt'; name='round768_stator-90x60-s36v2-808448' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778075493794.txt'; name='round769_stator-121x72-s36rot3-791552' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778075497894.txt'; name='round770_rotor-73x-146944' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778075506410.txt'; name='round771_rotor-73x-141312' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778075511760.txt'; name='round772_rotor-135x73-455168' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778075516667.txt'; name='round773_stator-135x73-304128' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778075522087.txt'; name='round774_135x73-728576' }
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
