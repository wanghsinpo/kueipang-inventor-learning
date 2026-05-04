param([string]$folder = $PSScriptRoot)

& (Join-Path (Split-Path $PSScriptRoot -Parent) 'auto_ring_v3.ps1') -folder $folder
