BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')
}

Describe 'Get-DOTExecutable' {
    It 'throws a friendly error when Graphviz is not installed' {
        Mock Resolve-Path -ModuleName AzViz { }
        Mock Get-Command -ModuleName AzViz { } -ParameterFilter { $Name -eq 'dot' }

        { InModuleScope AzViz { Get-DOTExecutable } } |
            Should -Throw '*Graphviz*not installed*https://graphviz.org/download/*'
    }

    It 'looks up dot on PATH without raising a CommandNotFound error' {
        Mock Resolve-Path -ModuleName AzViz { }
        Mock Get-Command -ModuleName AzViz { } -ParameterFilter { $Name -eq 'dot' }

        InModuleScope AzViz { try { Get-DOTExecutable } catch { } }

        Should -Invoke Get-Command -ModuleName AzViz -Times 1 -Exactly -ParameterFilter {
            $Name -eq 'dot' -and $ErrorAction -eq 'SilentlyContinue'
        }
    }

    It 'returns the dot executable when it is found' {
        $fakeDot = New-Item -Path (Join-Path $TestDrive 'dot') -ItemType File -Force
        Mock Resolve-Path -ModuleName AzViz { [pscustomobject]@{ Path = $fakeDot.FullName } }
        Mock Get-Command -ModuleName AzViz { } -ParameterFilter { $Name -eq 'dot' }

        $result = InModuleScope AzViz { Get-DOTExecutable }

        $result.FullName | Should -Be $fakeDot.FullName
    }
}
