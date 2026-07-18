$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "restore-skin-core.ps1") @args
exit $LASTEXITCODE
