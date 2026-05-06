$desk = Join-Path $env:USERPROFILE 'Desktop\test'
$base = Join-Path $env:USERPROFILE '.claude\projects\C--Users----Desktop-test\fc6835c2-f8f6-4f26-b809-53a234e8a02c\tool-results'
$files = @(
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073869030.txt'; name='round735_stator-160x80-s24v1-737792' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073874627.txt'; name='round736_stator-160x80-s24s1-733696' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073882884.txt'; name='round737_rotor-140x90-r48x17-625664' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073887783.txt'; name='round738_rotor-136x80-assm-1144832' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073896318.txt'; name='round739_rotor-160x80-r28t30-202752' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073899933.txt'; name='round740_rotor-160x80-punch1-95744' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073908198.txt'; name='round741_rotor-160x80-punch-103936' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778073954790.txt'; name='round742_stator-100x53-s24inner-537600' }
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
