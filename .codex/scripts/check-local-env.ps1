[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ForwardedArguments
)

# Compatibility entry point. All checks now live in the cloud-build setup script.
$target = Join-Path $PSScriptRoot 'check-cloud-build-setup.ps1'
& $target @ForwardedArguments
exit $LASTEXITCODE