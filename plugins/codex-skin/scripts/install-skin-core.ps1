[CmdletBinding()]
param(
  [int]$Port = 9335,
  [string]$Theme = 'salary-cat',
  [switch]$NoShortcuts
)

$ErrorActionPreference = 'Stop'
$SkillRoot = Split-Path -Parent $PSScriptRoot
$StateRoot = Join-Path $env:LOCALAPPDATA 'Codex Skin'
New-Item -ItemType Directory -Force -Path $StateRoot | Out-Null
$ConfigPath = Join-Path $HOME '.codex\config.toml'
$BackupPath = Join-Path $StateRoot 'config.before-codex-skin.toml'
if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Codex config not found: $ConfigPath" }
$node = (Get-Command node -ErrorAction Stop).Source
$themeTool = Join-Path $PSScriptRoot 'theme-tool.mjs'
& $node $themeTool apply --theme $Theme --platform win32 --config $ConfigPath --backup $BackupPath
if ($LASTEXITCODE -ne 0) { throw "Failed to configure base theme '$Theme'." }

if (-not $NoShortcuts) {
  $shell = New-Object -ComObject WScript.Shell
  $desktop = [Environment]::GetFolderPath('Desktop')
  $startMenu = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs'
  $powershell = (Get-Command powershell.exe).Source
  $startScript = Join-Path $PSScriptRoot 'start-skin-core.ps1'
  $restoreScript = Join-Path $PSScriptRoot 'restore-skin-core.ps1'
  foreach ($folder in @($desktop, $startMenu)) {
    $shortcut = $shell.CreateShortcut((Join-Path $folder 'Codex Skin.lnk'))
    $shortcut.TargetPath = $powershell
    $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$startScript`" -Port $Port -Theme `"$Theme`""
    $shortcut.WorkingDirectory = $SkillRoot
    $shortcut.Description = 'Launch Codex with the Dream/Fiona full interface skin'
    $shortcut.Save()
  }
  $restore = $shell.CreateShortcut((Join-Path $desktop 'Codex Skin - Restore.lnk'))
  $restore.TargetPath = $powershell
  $restore.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$restoreScript`" -Port $Port"
  $restore.WorkingDirectory = $SkillRoot
  $restore.Description = 'Remove the live Codex Skin'
  $restore.Save()
}

Write-Host "Codex Skin theme '$Theme' installed. Launch it with the created shortcut or start-skin-core.ps1."
