$base = [System.IO.Path]::Combine($env:USERPROFILE, '.claude', 'projects', 'C--Users----Desktop-test', 'fc6835c2-f8f6-4f26-b809-53a234e8a02c', 'tool-results')
$desk = [System.IO.Path]::Combine($env:USERPROFILE, 'Desktop', 'test')
$files = @(
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777948674533.txt'; dst='round357_8inch-ring-71680\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777948803036.txt'; dst='round358_temp-probe-retainer-ring-88064\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777948807550.txt'; dst='round359_PR47A-dummy-ring-130048\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777948811036.txt'; dst='round360_limit-ring-113664\real.ipt' }
)
foreach ($f in $files) {
    $srcPath = [System.IO.Path]::Combine($base, $f.src)
    $dstPath = [System.IO.Path]::Combine($desk, $f.dst)
    $dstDir = [System.IO.Path]::GetDirectoryName($dstPath)
    [System.IO.Directory]::CreateDirectory($dstDir) | Out-Null
    $raw = [System.IO.File]::ReadAllText($srcPath, [System.Text.Encoding]::UTF8)
    $json = $raw | ConvertFrom-Json
    if ($json.content -is [string]) { $b64 = $json.content } else { $b64 = $json.content[0].embeddedResource.contents.blob }
    $bytes = [Convert]::FromBase64String($b64)
    [IO.File]::WriteAllBytes($dstPath, $bytes)
    Write-Host ('OK: ' + $f.dst + ' = ' + $bytes.Length + ' bytes')
}
