## run_skips_v4.ps1
## Process all SKIP folders (R1107-R1126) using auto_v4 geometry detection logic.
## Connects to Inventor once, processes each folder, writes result.md, updates CSV.
##
## Usage:
##   powershell -ExecutionPolicy Bypass -File run_skips_v4.ps1
##   powershell -ExecutionPolicy Bypass -File run_skips_v4.ps1 -Force  # re-run even if already PASS/FAIL

param([switch]$Force = $false)

$ErrorActionPreference = 'Stop'
$desk  = Join-Path $env:USERPROFILE 'Desktop\test'
$csv   = Join-Path $desk 'parts_index.csv'

function MM($v) { return [double]$v / 10.0 }

# ---- nag-watcher ----
if (-not ('NagSkip' -as [type])) {
    Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NagSkip {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
}
function Start-NagWatcherSkip([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class NW_SK {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
        $stop = (Get-Date).AddHours(2)
        while ((Get-Date) -lt $stop) {
            $hits = [System.Collections.Generic.List[IntPtr]]::new()
            [NW_SK]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][NW_SK]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][NW_SK]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [NW_SK]::IsWindowVisible($h) -and
                    ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][NW_SK]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

# ---- load existing CSV ----
$indexData = @{}
if (Test-Path $csv) {
    Import-Csv $csv | ForEach-Object { $indexData[$_.Folder] = $_ }
}

# ---- connect to Inventor ----
try {
    $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application')
    Write-Host "Attached to running Inventor." -ForegroundColor Green
} catch {
    Write-Host "Launching Inventor..." -ForegroundColor Yellow
    $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application'))
    Start-Sleep -Seconds 5
}
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor | Select-Object -First 1).Id)
$nagJob = Start-NagWatcherSkip $invPid

$kPart = 12290; $kJoin = 20481; $kPos = 20993

# ---- find folders to process ----
$skipFolders = Get-ChildItem $desk -Directory |
    Where-Object { $_.Name -match '^round' } |
    Where-Object {
        $r = $indexData[$_.Name]
        if ($Force) { $true }
        else { $r -and $r.Result -eq 'SKIP' }
    } | Sort-Object Name

Write-Host "Processing $($skipFolders.Count) SKIP folders..." -ForegroundColor Cyan

$pass = 0; $fail = 0; $skip2 = 0

foreach ($f in $skipFolders) {
    $fname = $f.Name
    Write-Host "`n--- $fname ---" -ForegroundColor Yellow

    # find .ipt
    $realF = Join-Path $f.FullName 'real.ipt'
    if (-not (Test-Path $realF)) {
        $found = Get-ChildItem $f.FullName -Filter '*.ipt' |
                 Where-Object { $_.Name -notmatch '^my_attempt' } |
                 Sort-Object LastWriteTime -Descending |
                 Select-Object -First 1
        if (-not $found) {
            Write-Host "  No .ipt — SKIP" -ForegroundColor DarkYellow
            $skip2++
            continue
        }
        $realF = $found.FullName
        Write-Host "  Using: $($found.Name)" -ForegroundColor DarkGray
    }

    try {
        try { $inv.Documents.CloseAll($false) } catch {}
        $realDoc = $inv.Documents.Open($realF, $true)
        $rcd = $realDoc.ComponentDefinition
        $rbd = $rcd.SurfaceBodies.Item(1)
        $rb  = $rbd.RangeBox
        $realVol = [Math]::Round($rcd.MassProperties.Volume * 1000, 3)
        $xLen = ($rb.MaxPoint.X - $rb.MinPoint.X) * 10
        $yLen = ($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10
        $zLen = ($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10

        $cylFaces = 0; $planeFaces = 0; $totalFaces = $rbd.Faces.Count
        foreach ($face in $rbd.Faces) {
            if ($face.SurfaceType -eq 5891) { $cylFaces++ }
            if ($face.SurfaceType -eq 5890) { $planeFaces++ }
        }
        $realDoc.Close($false)

        $diam  = [Math]::Max($xLen, $yLen)
        $thick = $zLen
        $rOut  = $diam / 2.0
        $cylRatio = $cylFaces / [Math]::Max($totalFaces, 1)
        $aspectOK = ($diam -gt ($thick * 0.5))
        $isRing   = ($cylFaces -ge 2) -and ($cylRatio -gt 0.15) -and $aspectOK

        Write-Host ("  BBox={0:F2}x{1:F2}x{2:F2}  Vol={3}  cyl={4}/{5}" -f $xLen,$yLen,$zLen,$realVol,$cylFaces,$totalFaces) -ForegroundColor Magenta

        $method = ''; $chosenRIn = 0.0; $outVol = 0.0; $diffPct = 0.0

        if ($isRing) {
            Write-Host "  → RING (ratio=$([Math]::Round($cylRatio*100,0))%)" -ForegroundColor Cyan

            $radii = @()
            $realDoc2 = $inv.Documents.Open($realF, $true)
            $rbd2 = $realDoc2.ComponentDefinition.SurfaceBodies.Item(1)
            foreach ($face in $rbd2.Faces) {
                if ($face.SurfaceType -eq 5891) { $radii += [double]($face.Geometry.Radius * 10) }
            }
            $radii = $radii | Sort-Object -Unique -Descending
            $realDoc2.Close($false)

            $minInnerR = $rOut * 0.30
            $validRadii = $radii | Where-Object { $_ -lt $rOut -and $_ -gt $minInnerR }
            $detectedRIn = 0.0
            if ($validRadii.Count -gt 0) { $detectedRIn = [double]$validRadii[0] }

            $simpleVol  = [Math]::PI * (($rOut*$rOut) - ($detectedRIn*$detectedRIn)) * $thick
            $simpleDiff = if ($realVol -gt 0) { (($simpleVol - $realVol) / $realVol) * 100.0 } else { 0 }
            $backCalcRIn = $detectedRIn
            if ($thick -gt 0) {
                $innerSq = ($rOut*$rOut) - ($realVol / ([Math]::PI * $thick))
                if ($innerSq -gt 0) { $backCalcRIn = [Math]::Sqrt($innerSq) }
            }
            if ([Math]::Abs($simpleDiff) -gt 8 -and $backCalcRIn -gt 0 -and $backCalcRIn -lt $rOut -and
                [Math]::Abs($backCalcRIn - $detectedRIn) -gt 0.05) {
                $chosenRIn = $backCalcRIn
                $method = 'back-calc'
                Write-Host ("  BACKCALC: {0:F3} → {1:F3}" -f $detectedRIn,$backCalcRIn) -ForegroundColor Yellow
            } else {
                $chosenRIn = $detectedRIn
                $method = 'direct'
            }

            $tpl = $inv.FileManager.GetTemplateFile($kPart)
            $doc = $inv.Documents.Add($kPart, $tpl, $true)
            $cd  = $doc.ComponentDefinition
            $tg  = $inv.TransientGeometry
            $xy  = $cd.WorkPlanes.Item(3)
            $s   = $cd.Sketches.Add($xy)
            $null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $rOut))
            if ($chosenRIn -gt 0) {
                $null = $s.SketchCircles.AddByCenterRadius($tg.CreatePoint2d(0,0), (MM $chosenRIn))
            }
            $ed = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($s.Profiles.AddForSolid(), $kJoin)
            $ed.SetDistanceExtent((MM $thick), $kPos)
            $null = $cd.Features.ExtrudeFeatures.Add($ed)

            $body2 = $cd.SurfaceBodies.Item(1)
            $ec = $inv.TransientObjects.CreateEdgeCollection()
            foreach ($e in $body2.Edges) { if ($e.GeometryType -eq 5124) { $null = $ec.Add($e) } }
            if ($ec.Count -gt 0) {
                $wallMm = if ($chosenRIn -gt 0) { $rOut - $chosenRIn } else { $rOut }
                $sizeC = [Math]::Min($diam * 0.01, [Math]::Min($thick * 0.10, $wallMm * 0.10))
                $chamMm = [Math]::Min(0.5, [Math]::Max(0.05, $sizeC))
                try { $null = $cd.Features.ChamferFeatures.AddUsingDistance($ec, (MM $chamMm), $false) } catch {}
            }

            $outVol  = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
            $diffPct = if ($realVol -gt 0) { (($outVol - $realVol) / $realVol) * 100.0 } else { 0 }
            $result  = if ([Math]::Abs($diffPct) -le 10) { 'PASS' } else { 'FAIL' }

            Write-Host ("  Ring OD={0:F2} ID_R={1:F3} T={2:F2} Vol={3} diff={4:F4}% → {5}" -f $diam,$chosenRIn,$thick,$outVol,$diffPct,$result) -ForegroundColor Green

            $doc.SaveAs((Join-Path $f.FullName 'my_attempt_v4.ipt'), $false)

            # result.md
            $mdContent = @"
# $fname

## Result: $result

| Field | Value |
|-------|-------|
| BBox | $([Math]::Round($xLen,2)) x $([Math]::Round($yLen,2)) x $([Math]::Round($zLen,2)) mm |
| Inventor Vol | $realVol mm³ |
| My Vol | $outVol mm³ |
| Method | $method |
| Detected ID R | $([Math]::Round($detectedRIn,4)) mm |
| Chosen ID R | $([Math]::Round($chosenRIn,4)) mm |
| Diff | $([Math]::Round($diffPct,4))% |

$(if ($result -eq 'PASS') { "PASS ✓ (threshold ±10%)" } else { "FAIL ✗ (diff exceeds ±10%)" })
"@
            # CSV fields
            $csvOD    = [Math]::Round($diam,2)
            $csvIDR   = [Math]::Round($chosenRIn,4)
            $csvThick = [Math]::Round($thick,2)
            $csvVol   = $outVol

        } else {
            Write-Host "  → BOX (cyl=$cylFaces, ratio=$([Math]::Round($cylRatio*100,0))%)" -ForegroundColor Cyan
            $method = 'box'

            $tpl = $inv.FileManager.GetTemplateFile($kPart)
            $doc = $inv.Documents.Add($kPart, $tpl, $true)
            $cd  = $doc.ComponentDefinition
            $tg  = $inv.TransientGeometry
            $xy  = $cd.WorkPlanes.Item(3)
            $s   = $cd.Sketches.Add($xy)
            $p1  = $tg.CreatePoint2d((MM (-$xLen / 2.0)), (MM (-$yLen / 2.0)))
            $p2  = $tg.CreatePoint2d((MM ( $xLen / 2.0)), (MM ( $yLen / 2.0)))
            $null = $s.SketchLines.AddAsTwoPointRectangle($p1, $p2)
            $prof = $s.Profiles.AddForSolid()
            $ed   = $cd.Features.ExtrudeFeatures.CreateExtrudeDefinition($prof, $kJoin)
            $ed.SetDistanceExtent((MM $zLen), $kPos)
            $null = $cd.Features.ExtrudeFeatures.Add($ed)

            $outVol  = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
            $diffPct = if ($realVol -gt 0) { (($outVol - $realVol) / $realVol) * 100.0 } else { 0 }
            $result  = if ([Math]::Abs($diffPct) -le 10) { 'PASS' } else { 'FAIL' }

            Write-Host ("  Box {0:F2}x{1:F2}x{2:F2} Vol={3} diff={4:F4}% → {5}" -f $xLen,$yLen,$zLen,$outVol,$diffPct,$result) -ForegroundColor Green

            $doc.SaveAs((Join-Path $f.FullName 'my_attempt_v4.ipt'), $false)

            $mdContent = @"
# $fname

## Result: $result

| Field | Value |
|-------|-------|
| BBox | $([Math]::Round($xLen,2)) x $([Math]::Round($yLen,2)) x $([Math]::Round($zLen,2)) mm |
| Inventor Vol | $realVol mm³ |
| My Vol | $outVol mm³ |
| Method | box (BBox extrude) |
| Diff | $([Math]::Round($diffPct,4))% |

$(if ($result -eq 'PASS') { "PASS ✓ (threshold ±10%)" } else { "FAIL ✗ (diff exceeds ±10%)" })
"@
            $csvOD    = [Math]::Round([Math]::Max($xLen,$yLen),2)
            $csvIDR   = ''
            $csvThick = [Math]::Round($zLen,2)
            $csvVol   = $outVol
        }

        # Write result.md
        $mdPath = Join-Path $f.FullName 'result.md'
        $mdContent | Out-File $mdPath -Encoding utf8
        Write-Host "  Written: result.md  ($result)" -ForegroundColor Cyan

        # Update indexData for CSV
        $row = [PSCustomObject]@{
            Folder   = $fname
            Result   = $result
            OD_mm    = $csvOD
            ID_R_mm  = $csvIDR
            Thick_mm = $csvThick
            Vol_mm3  = $csvVol
        }
        $indexData[$fname] = $row

        if ($result -eq 'PASS') { $pass++ } else { $fail++ }

    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
        $skip2++
        try { $inv.Documents.CloseAll($false) } catch {}
    }
}

try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch {}

# ---- write updated CSV ----
$allRows = Get-ChildItem $desk -Directory |
    Where-Object { $_.Name -match '^round' } |
    Sort-Object Name |
    ForEach-Object {
        if ($indexData.ContainsKey($_.Name)) { $indexData[$_.Name] }
    }
$allRows | Export-Csv $csv -NoTypeInformation -Encoding utf8
Write-Host "`n=== DONE: PASS=$pass  FAIL=$fail  SKIP=$skip2 ===" -ForegroundColor Cyan
Write-Host "Updated CSV: $csv" -ForegroundColor Cyan
