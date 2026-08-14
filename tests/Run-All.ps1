[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$tests = @(
    Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.Tests.ps1' -File |
        Sort-Object Name)

foreach ($test in $tests) {
    Write-Host "Running $($test.Name)"
    & $test.FullName
}

Write-Output 'All blade-driver-catalog tests passed.'
