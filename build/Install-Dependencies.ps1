<#
.SYNOPSIS
Installs the modules needed to import, test and analyze AzViz.

.DESCRIPTION
Installs every RequiredModule from AzViz.psd1 plus the pinned test tooling, using
PSResourceGet (ships with PowerShell 7.4+). AllUsers scope needs an elevated
session (Administrator on Windows, sudo on Linux/macOS).
#>
[CmdletBinding()]
param(
    [ValidateSet('AllUsers', 'CurrentUser')]
    [string] $Scope = 'AllUsers'
)

$ErrorActionPreference = 'Stop'

# Test tooling is pinned so every OS and every run uses the same versions.
$Tools = [ordered]@{
    Pester           = '5.9.1'
    PSScriptAnalyzer = '1.25.0'
}

$Manifest = Import-PowerShellDataFile (Join-Path $PSScriptRoot '..' 'AzViz' 'AzViz.psd1')

foreach ($Module in $Manifest.RequiredModules) {
    Write-Information "Installing $($Module.ModuleName) >= $($Module.ModuleVersion)" -InformationAction Continue
    Install-PSResource -Name $Module.ModuleName -Version "[$($Module.ModuleVersion),)" -Repository PSGallery `
        -Scope $Scope -TrustRepository -AcceptLicense -Quiet
}

foreach ($Name in $Tools.Keys) {
    Write-Information "Installing $Name $($Tools[$Name])" -InformationAction Continue
    Install-PSResource -Name $Name -Version $Tools[$Name] -Repository PSGallery `
        -Scope $Scope -TrustRepository -AcceptLicense -Quiet
}

Get-InstalledPSResource -Name (@($Manifest.RequiredModules.ModuleName) + @($Tools.Keys)) -Scope $Scope |
    Sort-Object Name, Version |
    Format-Table Name, Version -AutoSize |
    Out-String |
    Write-Information -InformationAction Continue
