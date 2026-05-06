$desk = Join-Path $env:USERPROFILE 'Desktop\test'
$base = Join-Path $env:USERPROFILE '.claude\projects\C--Users----Desktop-test\fc6835c2-f8f6-4f26-b809-53a234e8a02c\tool-results'
$files = @(
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778069952124.txt'; name='round679_rotor-117x60-r30-t70-178688' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778069956574.txt'; name='round680_rotor-117x60-r30-199168' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778069960986.txt'; name='round681_rotor-117x60-r30-194048' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778069965710.txt'; name='round682_rotor-117x60-r30-198144' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778069977176.txt'; name='round683_rotor-90x47-r11-347648' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778069982910.txt'; name='round684_stator-90x47-50s-664064' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778069988982.txt'; name='round685_stator-90x47-45s-outer2-491008' },
    [PSCustomObject]@{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1778070048435.txt'; name='round686_stator-90x48-2073600' }
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
