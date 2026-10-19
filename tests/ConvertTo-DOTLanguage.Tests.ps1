BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')
    $webappFixture = Join-Path $FixtureRoot 'arm' 'webapp.json'
}

Describe 'ConvertTo-DOTLanguage (offline, ARM fixture)' {
    BeforeAll {
        Mock Get-AzContext -ModuleName AzViz {
            [pscustomobject]@{
                Subscription = [pscustomobject]@{ Name = 'sub-fixture'; Id = '00000000-0000-0000-0000-000000000000' }
            }
        }
        Mock Get-AzResourceGroup -ModuleName AzViz { [pscustomobject]@{ ResourceGroupName = 'rg-fixture'; Location = 'westus2' } }
        Mock Get-AzNetworkWatcher -ModuleName AzViz { }
        Mock Get-AzVirtualNetwork -ModuleName AzViz { }
        Mock Export-AzResourceGroup -ModuleName AzViz {
            Copy-Item -Path $webappFixture -Destination $Path -Force
            [pscustomobject]@{ Path = $Path }
        }
        $fakeDot = New-Item -Path (Join-Path $TestDrive 'dot') -ItemType File -Force
        Mock Get-DOTExecutable -ModuleName AzViz { $fakeDot }
        # Stand in for Graphviz: return the generated DOT source unchanged.
        Mock Invoke-DOTExecutable -ModuleName AzViz { Get-Content -Path $Path -Raw }

        $dot = InModuleScope AzViz {
            ConvertTo-DOTLanguage -Targets 'rg-fixture' -Direction left-to-right -Theme dark
        } | Out-String
    }

    It 'emits a digraph' {
        $dot | Should -Match 'digraph\s+Visualization'
    }

    It 'honours the direction' {
        $dot | Should -Match 'rankdir\s*=\s*"?LR'
    }

    It 'uses the theme colors' {
        $dot | Should -Match 'bgcolor\s*=\s*"?grey7'
    }

    It 'contains a node for each resource' {
        $dot | Should -Match '"microsoft\.web/sites/app-fixture01"'
        $dot | Should -Match '"microsoft\.web/serverfarms/plan-fixture01"'
        $dot | Should -Match '"microsoft\.storage/storageaccounts/stfixture01"'
    }

    It 'contains the dependsOn edge' {
        $dot | Should -Match '"microsoft\.web/sites/app-fixture01"\s*->\s*"microsoft\.web/serverfarms/plan-fixture01"'
    }

    It 'labels the resource group cluster' {
        # Existing behaviour: special characters such as '-' are stripped from cluster labels.
        $dot | Should -Match 'ResourceGroup: rgfixture'
    }
}
