BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')
}

Describe 'Test-AzLogin' {
    BeforeEach {
        Mock Connect-AzAccount -ModuleName AzViz { throw 'Connect-AzAccount must never be called' }
    }

    It 'returns $true when an Azure context exists' {
        Mock Get-AzContext -ModuleName AzViz { [pscustomobject]@{ Name = 'fixture-context' } }

        InModuleScope AzViz { Test-AzLogin } | Should -BeTrue
    }

    It 'throws a clear error instead of prompting when there is no Azure context' {
        Mock Get-AzContext -ModuleName AzViz { }

        { InModuleScope AzViz { Test-AzLogin } } | Should -Throw '*Not signed in to Azure*Connect-AzAccount*'
        Should -Invoke Connect-AzAccount -ModuleName AzViz -Times 0 -Exactly
    }

    It 'throws a clear error instead of prompting when Get-AzContext fails' {
        Mock Get-AzContext -ModuleName AzViz {
            throw [System.Management.Automation.PSInvalidOperationException]::new('Run Connect-AzAccount to login.')
        }

        { InModuleScope AzViz { Test-AzLogin } } | Should -Throw '*Not signed in to Azure*'
        Should -Invoke Connect-AzAccount -ModuleName AzViz -Times 0 -Exactly
    }
}

Describe 'Export-AzViz when not signed in' {
    It 'fails fast without prompting' {
        $fakeDot = New-Item -Path (Join-Path $TestDrive 'dot') -ItemType File -Force
        Mock Get-DOTExecutable -ModuleName AzViz { $fakeDot }
        Mock Get-AzContext -ModuleName AzViz { }
        Mock Connect-AzAccount -ModuleName AzViz { throw 'Connect-AzAccount must never be called' }

        { Export-AzViz -ResourceGroup 'rg-fixture' } | Should -Throw '*Not signed in to Azure*'
        Should -Invoke Connect-AzAccount -ModuleName AzViz -Times 0 -Exactly
    }
}

Describe 'Export-AzViz when Graphviz is missing' {
    It 'fails with the friendly Graphviz error' {
        Mock Resolve-Path -ModuleName AzViz { }
        Mock Get-Command -ModuleName AzViz { } -ParameterFilter { $Name -eq 'dot' }

        { Export-AzViz -ResourceGroup 'rg-fixture' } | Should -Throw '*Graphviz*not installed*'
    }
}
