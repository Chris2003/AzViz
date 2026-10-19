<#
.SYNOPSIS
Runs the AzViz Pester 5 suite (offline; Azure cmdlets are mocked).
#>
[CmdletBinding()]
param(
    [string] $Path = (Join-Path $PSScriptRoot '..' 'tests'),
    [string] $ResultPath = (Join-Path $PSScriptRoot '..' 'testResults.xml')
)

$ErrorActionPreference = 'Stop'
Import-Module Pester -RequiredVersion 5.9.1

$Config = New-PesterConfiguration
$Config.Run.Path = $Path
$Config.Run.Exit = $true
$Config.Output.Verbosity = 'Detailed'
$Config.TestResult.Enabled = $true
$Config.TestResult.OutputFormat = 'NUnitXml'
$Config.TestResult.OutputPath = $ResultPath

Invoke-Pester -Configuration $Config
