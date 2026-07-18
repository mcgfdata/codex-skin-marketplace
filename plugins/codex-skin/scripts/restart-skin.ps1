$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "start-skin-core.ps1") -RestartExisting @args
exit $LASTEXITCODE
