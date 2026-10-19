BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')
}

Describe 'Write-CustomHost' {
    It 'writes indented messages to the information stream tagged AzViz' {
        $records = @(InModuleScope AzViz {
            Write-CustomHost -String 'hello fixture' -Indentation 2 -InformationVariable captured
            $captured
        })

        $records | Should -HaveCount 1
        $records[0].MessageData | Should -BeLike '      * hello fixture'
        $records[0].Tags | Should -Contain 'AzViz'
    }

    It 'writes nothing to the success stream' {
        InModuleScope AzViz { Write-CustomHost -String 'quiet' } | Should -BeNullOrEmpty
    }
}
