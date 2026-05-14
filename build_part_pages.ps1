## build_part_pages.ps1
## Generate <folder>/view.html for each PASS part with result.md + thumbnail + nav links.
## Run on demand (skips existing).

param([switch]$Force = $false)

$desk = "$env:USERPROFILE\Desktop\test"
$folders = Get-ChildItem $desk -Directory | Where-Object { $_.Name -match '^round' }

$created = 0
foreach ($f in $folders) {
    $viewPath = Join-Path $f.FullName 'view.html'
    if ((Test-Path $viewPath) -and -not $Force) { continue }

    $rm = Join-Path $f.FullName 'result.md'
    if (-not (Test-Path $rm)) { continue }
    $rmContent = Get-Content $rm -Raw
    # Escape HTML
    $rmHtml = $rmContent -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'

    $thumb = Join-Path $f.FullName 'thumbnail.bmp'
    $thumbTag = if (Test-Path $thumb) {
        "<img src='thumbnail.bmp' style='max-width:400px; background:#0f3460; border-radius:6px'>"
    } else {
        "<div style='width:400px; height:300px; background:#222; display:flex; align-items:center; justify-content:center; color:#666'>No thumbnail</div>"
    }

    # File list
    $files = Get-ChildItem $f.FullName | Where-Object { -not $_.PSIsContainer } | Sort-Object Name
    $fileList = ""
    foreach ($file in $files) {
        $size = if ($file.Length -gt 1KB) { "$([Math]::Round($file.Length/1KB))KB" } else { "$($file.Length)B" }
        $fileList += "<li><a href='$($file.Name)' target='_blank'>$($file.Name)</a> <span style='color:#888'>($size)</span></li>`n"
    }

    $html = @"
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>$($f.Name)</title>
<style>
  body { font-family: 'Segoe UI', Arial, sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; max-width: 1200px; margin: 0 auto; }
  h1 { color: #f0c040; }
  .row { display: flex; gap: 20px; align-items: flex-start; }
  .col { flex: 1; }
  pre { background: #161b22; padding: 16px; border-radius: 6px; white-space: pre-wrap; word-break: break-word; font-family: 'Consolas', monospace; font-size: 13px; }
  ul { list-style: none; padding: 0; }
  ul li { padding: 4px 0; }
  a { color: #58a6ff; text-decoration: none; }
  a:hover { text-decoration: underline; }
</style>
</head>
<body>
<h1>📦 $($f.Name)</h1>
<p><a href='../index.html'>← All parts</a></p>

<div class='row'>
  <div class='col'>
    <h3>Preview</h3>
    $thumbTag
    <h3>Files</h3>
    <ul>
$fileList
    </ul>
  </div>
  <div class='col'>
    <h3>result.md</h3>
    <pre>$rmHtml</pre>
  </div>
</div>
</body>
</html>
"@

    $html | Out-File $viewPath -Encoding utf8
    $created++
}

Write-Host "Created $created view.html pages"
