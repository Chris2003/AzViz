BeforeDiscovery {
    $moduleRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'AzViz'
    $sourceFiles = Get-ChildItem (Join-Path $moduleRoot 'src') -Filter *.ps1 -Recurse |
        ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
    $functionFiles = $sourceFiles | Where-Object Name -ne 'Images.ps1'
}

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')
}

Describe 'Module manifest' {
    It 'is valid' {
        { Test-ModuleManifest -Path $ModuleManifest -ErrorAction Stop } | Should -Not -Throw
    }

    It 'requires PowerShell 7.4 or later' {
        (Import-PowerShellDataFile $ModuleManifest).PowerShellVersion | Should -Be '7.4'
    }

    It 'exports <_>' -ForEach 'Export-AzViz', 'Export-AzVizTenant' {
        Get-Command -Module AzViz -Name $_ -CommandType Function | Should -Not -BeNullOrEmpty
    }

    It 'resolves alias <Alias> to <Target>' -ForEach @(
        @{ Alias = 'AzViz'; Target = 'Export-AzViz' }
        @{ Alias = 'Get-TenantDiagrams'; Target = 'Export-AzVizTenant' }
    ) {
        (Get-Alias -Name $Alias -ErrorAction Stop).ResolvedCommandName | Should -Be $Target
    }
}

Describe 'Source file <Name>' -ForEach $sourceFiles {
    BeforeAll {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
        $commands = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.CommandAst] }, $true) |
            ForEach-Object { $_.GetCommandName() }
    }

    It 'does not call Write-Host' {
        $commands | Should -Not -Contain 'Write-Host'
    }

    It 'does not call Invoke-Expression' {
        $commands | Should -Not -Contain 'Invoke-Expression'
        $commands | Should -Not -Contain 'iex'
    }
}

Describe 'Source file <Name> naming' -ForEach $functionFiles {
    It 'defines a function matching its file name' {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)
        $names = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $false).Name
        $names | Should -Contain ([System.IO.Path]::GetFileNameWithoutExtension($Path))
    }
}
