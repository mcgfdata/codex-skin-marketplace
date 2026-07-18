$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $ScriptDir "verify-skin-core.ps1") @args
exit $LASTEXITCODE
