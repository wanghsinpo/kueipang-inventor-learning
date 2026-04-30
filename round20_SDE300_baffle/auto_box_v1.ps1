param([string]$folder = $PSScriptRoot)

& (Join-Path (Split-Path $PSScriptRoot -Parent) 'auto_box_v1.ps1') -folder $folder
