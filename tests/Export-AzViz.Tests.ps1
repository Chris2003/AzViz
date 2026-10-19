BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')
}

Describe 'Export-AzViz parameter pass-through' {
    BeforeAll {
        $fakeDot = New-Item -Path (Join-Path $TestDrive 'dot') -ItemType File -Force
        Mock Get-DOTExecutable -ModuleName AzViz { $fakeDot }
        Mock ConvertTo-DOTLanguage -ModuleName AzViz { }
    }

    It 'passes -Direction and -Theme to the DOT generator' {
        Export-AzViz -ResourceGroup 'rg-fixture' -Direction left-to-right -Theme neon

        Should -Invoke ConvertTo-DOTLanguage -ModuleName AzViz -Times 1 -Exactly -ParameterFilter {
            $Direction -eq 'left-to-right' -and $Theme -eq 'neon' -and $Targets -contains 'rg-fixture'
        }
    }

    It 'writes progress to the information stream only' {
        $output = Export-AzViz -ResourceGroup 'rg-fixture' -InformationVariable info

        $output | Should -BeNullOrEmpty
        $info.MessageData | Should -Not -BeNullOrEmpty
    }
}
