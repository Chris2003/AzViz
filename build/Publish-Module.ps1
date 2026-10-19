<#
.SYNOPSIS
Publishes AzViz to the PowerShell Gallery with PSResourceGet, or performs a dry run.

.DESCRIPTION
Both modes validate the manifest and check that every RequiredModule can be resolved on
the PowerShell Gallery. A dry run then packs and publishes into a throwaway local
repository and inspects the resulting .nupkg. A real publish pushes to PSGallery using
the API key in $env:PSGALLERY_API_KEY and refuses to overwrite an existing version.
#>
[CmdletBinding()]
param(
    [switch] $DryRun,

    [string] $OutputPath = (Join-Path $PSScriptRoot '..' 'out')
)

$ErrorActionPreference = 'Stop'

$ModulePath = Join-Path $PSScriptRoot '..' 'AzViz'
$ManifestPath = Join-Path $ModulePath 'AzViz.psd1'
$Manifest = Test-ModuleManifest -Path $ManifestPath
$Version = $Manifest.Version.ToString()
Write-Information "AzViz $Version" -InformationAction Continue

foreach ($Dependency in (Import-PowerShellDataFile $ManifestPath).RequiredModules) {
    $Range = "[$($Dependency.ModuleVersion),)"
    $Found = Find-PSResource -Name $Dependency.ModuleName -Version $Range -Repository PSGallery -ErrorAction SilentlyContinue |
        Sort-Object Version -Descending |
        Select-Object -First 1
    if (-not $Found) {
        throw "RequiredModule $($Dependency.ModuleName) $Range is not available on the PowerShell Gallery."
    }
    Write-Information "  dependency $($Dependency.ModuleName) $Range -> $($Found.Version)" -InformationAction Continue
}

$Published = Find-PSResource -Name AzViz -Version $Version -Repository PSGallery -ErrorAction SilentlyContinue
if ($Published) {
    $Message = "AzViz $Version is already on the PowerShell Gallery; bump ModuleVersion before releasing."
    if ($DryRun) {
        Write-Warning $Message
    }
    else {
        throw $Message
    }
}

if ($DryRun) {
    $RepositoryName = "AzVizDryRun-$([guid]::NewGuid().ToString('N'))"
    $null = New-Item -Path $OutputPath -ItemType Directory -Force
    Register-PSResourceRepository -Name $RepositoryName -Uri (Resolve-Path $OutputPath).Path -Trusted
    try {
        # Dependencies were verified against PSGallery above; the local repository does not hold them.
        Publish-PSResource -Path $ModulePath -Repository $RepositoryName -SkipDependenciesCheck

        $Package = Get-ChildItem -Path $OutputPath -Filter "AzViz.$Version.nupkg" | Select-Object -First 1
        if (-not $Package) {
            throw "Dry run did not produce AzViz.$Version.nupkg in $OutputPath."
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $Zip = [System.IO.Compression.ZipFile]::OpenRead($Package.FullName)
        try {
            $Entries = $Zip.Entries.FullName
        }
        finally {
            $Zip.Dispose()
        }
        foreach ($Required in 'AzViz.psd1', 'AzViz.psm1', 'src/public/Export-AzViz.ps1') {
            if ($Entries -notcontains $Required) {
                throw "Package is missing $Required."
            }
        }
        Write-Information "Dry run OK: $($Package.Name) ($($Entries.Count) files)" -InformationAction Continue
    }
    finally {
        Unregister-PSResourceRepository -Name $RepositoryName
    }
}
else {
    if (-not $env:PSGALLERY_API_KEY) {
        throw 'PSGALLERY_API_KEY is not set.'
    }
    Publish-PSResource -Path $ModulePath -Repository PSGallery -ApiKey $env:PSGALLERY_API_KEY
    Write-Information "Published AzViz $Version to the PowerShell Gallery" -InformationAction Continue
}
