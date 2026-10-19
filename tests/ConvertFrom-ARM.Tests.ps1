BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')
    $webappFixture = Join-Path $FixtureRoot 'arm' 'webapp.json'
    $emptyFixture = Join-Path $FixtureRoot 'arm' 'empty.json'
}

Describe 'ConvertFrom-ARM' {
    BeforeEach {
        $tempFile = Join-Path $TestDrive 'armtemplate.tmp'
        Mock New-TemporaryFile -ModuleName AzViz { New-Item -Path $tempFile -ItemType File -Force }
    }

    Context 'TargetType File' {
        BeforeAll {
            $result = InModuleScope AzViz -Parameters @{ Target = $webappFixture } {
                ConvertFrom-ARM -TargetType File -Targets $Target
            }
        }

        It 'is reachable and names the target' {
            $result.Type | Should -Be 'File'
            $result.Name | Should -Be $webappFixture
        }

        It 'extracts dependsOn edges' {
            $edge = $result.Resources | Where-Object isdependent
            $edge.from | Should -Be 'app-fixture01'
            $edge.fromcateg | Should -Be 'Microsoft.Web/sites'
            $edge.to | Should -Be 'plan-fixture01'
            $edge.tocateg | Should -Be 'Microsoft.Web/serverfarms'
        }

        It 'keeps standalone resources within the category depth' {
            $result.Resources.from | Should -Contain 'plan-fixture01'
            $result.Resources.from | Should -Contain 'stfixture01'
            $result.Resources.from | Should -Not -Contain 'stfixture01/default'
        }

        It 'excludes network types handled by ConvertFrom-Network' {
            $result.Resources.from | Should -Not -Contain 'vnet-fixture01'
        }

        It 'does not delete the source template' {
            $webappFixture | Should -Exist
        }

        It 'cleans up its temporary file' {
            $tempFile | Should -Not -Exist
        }
    }

    Context 'TargetType Url' {
        It 'downloads, parses and cleans up the temporary file' {
            Mock Invoke-WebRequest -ModuleName AzViz { Copy-Item -Path $webappFixture -Destination $OutFile }

            $result = InModuleScope AzViz {
                ConvertFrom-ARM -TargetType Url -Targets 'https://example.invalid/azuredeploy.json'
            }

            $result.Type | Should -Be 'Url'
            ($result.Resources | Where-Object isdependent).to | Should -Be 'plan-fixture01'
            $tempFile | Should -Not -Exist
        }
    }

    Context 'TargetType Azure Resource Group' {
        It 'cleans up the exported template when resources are found' {
            Mock Export-AzResourceGroup -ModuleName AzViz {
                Copy-Item -Path $webappFixture -Destination $Path -Force
                [pscustomobject]@{ Path = $Path }
            }

            $result = InModuleScope AzViz { ConvertFrom-ARM -Targets 'rg-fixture' }

            $result.Name | Should -Be 'rg-fixture'
            $tempFile | Should -Not -Exist
        }

        It 'cleans up the exported template when no resources are found' {
            Mock Export-AzResourceGroup -ModuleName AzViz {
                Copy-Item -Path $emptyFixture -Destination $Path -Force
                [pscustomobject]@{ Path = $Path }
            }

            $result = InModuleScope AzViz { ConvertFrom-ARM -Targets 'rg-fixture' }

            $result | Should -BeNullOrEmpty
            $tempFile | Should -Not -Exist
        }

        It 'cleans up the temporary file when the export fails' {
            Mock Export-AzResourceGroup -ModuleName AzViz { throw 'export failed' }

            { InModuleScope AzViz { ConvertFrom-ARM -Targets 'rg-fixture' } } | Should -Throw 'export failed'
            $tempFile | Should -Not -Exist
        }
    }
}
