$base = [System.IO.Path]::Combine($env:USERPROFILE, '.claude', 'projects', 'C--Users----Desktop-test', 'fc6835c2-f8f6-4f26-b809-53a234e8a02c', 'tool-results')
$desk = [System.IO.Path]::Combine($env:USERPROFILE, 'Desktop', 'test')
$files = @(
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777949163162.txt'; dst='round361_end-ring-02-80384\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777949167317.txt'; dst='round362_tilter-liner-ring-small-179200\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777949171769.txt'; dst='round363_metal-ring-190976\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777949176554.txt'; dst='round364_conductive-iron-ring-73728\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777949185730.txt'; dst='round365_aluminum-ring-148480\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777949190670.txt'; dst='round366_passive-ring-246272\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777949195093.txt'; dst='round367_housing-airtest-ring2-164864\real.ipt' },
    @{ src='mcp-61e02088-dd3a-47ec-b5a9-22b937430d59-download_file_content-1777949199207.txt'; dst='round368_housing-airtest-ring-168448\real.ipt' }
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
