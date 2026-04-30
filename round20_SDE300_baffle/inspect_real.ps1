param([string]$folder = $PSScriptRoot)

$ErrorActionPreference = 'Stop'

function Start-NagWatcher([uint32]$invPid) {
    Start-Job -ScriptBlock {
        param($p)
        Add-Type @"
using System; using System.Runtime.InteropServices; using System.Text;
public class Nw20 {
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
    public delegate bool EnumProc(IntPtr h, IntPtr l);
}
"@
        $stop = (Get-Date).AddMinutes(3)
        while ((Get-Date) -lt $stop) {
            $hits = [System.Collections.Generic.List[IntPtr]]::new()
            [Nw20]::EnumWindows({param($h,$l)
                $sb = New-Object Text.StringBuilder 256
                [void][Nw20]::GetWindowText($h, $sb, 256)
                [uint32]$wp = 0
                [void][Nw20]::GetWindowThreadProcessId($h, [ref]$wp)
                if ($wp -eq $p -and [Nw20]::IsWindowVisible($h) -and ($sb.ToString() -match 'Configurator|Sign In|Welcome')) {
                    $script:hits.Add($h)
                }
                $true
            }, [IntPtr]::Zero) | Out-Null
            foreach ($h in $hits) { [void][Nw20]::PostMessage($h, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) }
            Start-Sleep -Milliseconds 500
        }
    } -ArgumentList $invPid
}

$realF = Join-Path $folder 'real.ipt'
try { $inv = [System.Runtime.InteropServices.Marshal]::GetActiveObject('Inventor.Application') }
catch { $inv = [Activator]::CreateInstance([Type]::GetTypeFromProgID('Inventor.Application')); Start-Sleep 2 }
$inv.Visible = $true
$invPid = [uint32]((Get-Process -Name Inventor | Select-Object -First 1).Id)
$nagJob = Start-NagWatcher $invPid

try { $inv.Documents.CloseAll($false) } catch { }
$doc = $inv.Documents.Open($realF, $true)
$cd = $doc.ComponentDefinition
$body = $cd.SurfaceBodies.Item(1)
$rb = $body.RangeBox

$x = [Math]::Round(($rb.MaxPoint.X - $rb.MinPoint.X) * 10, 3)
$y = [Math]::Round(($rb.MaxPoint.Y - $rb.MinPoint.Y) * 10, 3)
$z = [Math]::Round(($rb.MaxPoint.Z - $rb.MinPoint.Z) * 10, 3)
$vol = [Math]::Round($cd.MassProperties.Volume * 1000, 3)
$area = [Math]::Round($cd.MassProperties.Area * 100, 3)

$surfaceCounts = @{}
$radii = @()
foreach ($f in $body.Faces) {
    $key = [string]$f.SurfaceType
    if (-not $surfaceCounts.ContainsKey($key)) { $surfaceCounts[$key] = 0 }
    $surfaceCounts[$key]++
    if ($f.SurfaceType -eq 5891) {
        $radii += [Math]::Round([double]($f.Geometry.Radius * 10), 4)
    }
}

$radiiUnique = $radii | Sort-Object -Unique -Descending
Write-Host ("REAL bbox: {0} x {1} x {2} mm" -f $x, $y, $z)
Write-Host ("REAL volume: {0} mm^3 | area: {1} mm^2" -f $vol, $area)
Write-Host ("Face count: {0}" -f $body.Faces.Count)
Write-Host "Surface counts:"
$surfaceCounts.GetEnumerator() | Sort-Object Name | ForEach-Object { Write-Host ("  type {0}: {1}" -f $_.Key, $_.Value) }
Write-Host ("Cylinder radii mm: {0}" -f ($radiiUnique -join ', '))

$doc.Close($false)
try { $nagJob | Stop-Job; $nagJob | Remove-Job } catch { }
