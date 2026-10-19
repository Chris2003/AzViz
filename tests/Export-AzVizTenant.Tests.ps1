BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')
}

Describe 'Export-AzVizTenant' {
    BeforeAll {
        Mock Get-AzSubscription -ModuleName AzViz {
            [pscustomobject]@{ Name = 'sub-fixture-a'; Id = '00000000-0000-0000-0000-00000000000a' }
            [pscustomobject]@{ Name = 'sub-fixture-b'; Id = '00000000-0000-0000-0000-00000000000b' }
        }
        Mock Set-AzContext -ModuleName AzViz { }
        Mock Get-AzResourceGroup -ModuleName AzViz {
            [pscustomobject]@{ ResourceGroupName = 'rg-fixture-1' }
            [pscustomobject]@{ ResourceGroupName = 'rg-fixture-2' }
        }
        Mock Export-AzViz -ModuleName AzViz { }
        Mock Get-Date -ModuleName AzViz { '01-02-2026' }

        Export-AzVizTenant -Theme dark -OutputFilePath $TestDrive -OutputFormat svg
    }

    It 'calls Export-AzViz once per resource group per subscription' {
        Should -Invoke Export-AzViz -ModuleName AzViz -Times 4 -Exactly
    }

    It 'builds output paths with Join-Path' {
        $expected = Join-Path $TestDrive '01-02-2026' 'sub-fixture-b' 'rg-fixture-2.svg'
        Should -Invoke Export-AzViz -ModuleName AzViz -Times 1 -Exactly -ParameterFilter {
            $OutputFilePath -eq $expected -and $Theme -eq 'dark' -and $OutputFormat -eq 'svg'
        }
    }

    It 'creates one directory per subscription' {
        Join-Path $TestDrive '01-02-2026' 'sub-fixture-a' | Should -Exist
        Join-Path $TestDrive '01-02-2026' 'sub-fixture-b' | Should -Exist
    }

    It 'selects each subscription by id' {
        Should -Invoke Set-AzContext -ModuleName AzViz -Times 1 -Exactly -ParameterFilter {
            $SubscriptionId -eq '00000000-0000-0000-0000-00000000000a'
        }
    }

    It 'can be re-run into an existing output directory' {
        { Export-AzVizTenant -Theme light -OutputFilePath $TestDrive } | Should -Not -Throw
    }

    It 'is available as Get-TenantDiagrams' {
        { Get-TenantDiagrams -Theme light -OutputFilePath $TestDrive } | Should -Not -Throw
    }
}
