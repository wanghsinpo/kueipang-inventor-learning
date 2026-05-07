$desk = Join-Path $env:USERPROFILE 'Desktop\test'
$base = Join-Path $env:USERPROFILE '.claude\projects\C--Users----Desktop-test\fc6835c2-f8f6-4f26-b809-53a234e8a02c\tool-results'
$files = @(
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778140452497.txt'; name='round851_jig-sisuteel-od-172544' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778140457206.txt'; name='round852_sisuteel-singledip-218112' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778140461761.txt'; name='round853_sisuteel-singledip0004-222208' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778140466210.txt'; name='round854_sisuteel-singledip0003-218624' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778140471183.txt'; name='round855_sisuteel-224768' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778140475634.txt'; name='round856_sisuteel-doubledip0001-219136' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778140480370.txt'; name='round857_sisuteel-singleblock0001-236544' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778140484514.txt'; name='round858_sisuteel-singleblock-256000' }
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
