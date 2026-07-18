[CmdletBinding()]
param(
  [string]$Theme = "salary-cat",
  [int]$Port = 9335
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DesktopDir = [Environment]::GetFolderPath("Desktop")

& (Join-Path $ScriptDir "install-skin.ps1") -Theme $Theme -Port $Port
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$launchers = @(
  @{
    Path = Join-Path $DesktopDir "Codex Skin.ps1"
    Body = "& `"$ScriptDir\start-skin.ps1`" -Theme `"$Theme`" -Port $Port`n"
  },
  @{
    Path = Join-Path $DesktopDir "Codex Skin - Restart.ps1"
    Body = "& `"$ScriptDir\restart-skin.ps1`" -Theme `"$Theme`" -Port $Port`n"
  },
  @{
    Path = Join-Path $DesktopDir "Codex Skin - Restore.ps1"
    Body = "& `"$ScriptDir\restore-skin.ps1`" -Port $Port`n"
  }
)

foreach ($launcher in $launchers) {
  Set-Content -LiteralPath $launcher.Path -Value $launcher.Body -Encoding UTF8
}

Write-Host "Codex Skin setup complete."
Write-Host "Desktop launchers:"
foreach ($launcher in $launchers) {
  Write-Host "  $($launcher.Path)"
}
Write-Host "Run 'Codex Skin - Restart.ps1' after saving your current Codex work."
