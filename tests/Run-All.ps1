[CmdletBinding()]
param()

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# PowerShell 7.5+ otherwise converts ISO metadata strings into DateTime values.
if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
    $PSDefaultParameterValues['ConvertFrom-Json:DateKind'] = 'String'
}

$tests = @(
    Get-ChildItem -LiteralPath $PSScriptRoot -Filter '*.Tests.ps1' -File |
        Sort-Object Name)

foreach ($test in $tests) {
    Write-Host "Running $($test.Name)"
    & $test.FullName
}

Write-Output 'All blade-driver-catalog tests passed.'
