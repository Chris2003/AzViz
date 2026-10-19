BeforeAll {
    . (Join-Path $PSScriptRoot 'TestHelper.ps1')

    # A stand-in for Graphviz 'dot' that echoes its arguments, placed in a
    # directory whose path contains spaces to prove the call is quoted.
    $binDir = New-Item -Path (Join-Path $TestDrive 'Program Files' 'Graph viz') -ItemType Directory -Force
    if ($IsWindows) {
        $fakeDot = Join-Path $binDir 'dot.cmd'
        Set-Content -Path $fakeDot -Value '@echo ARG:%~1'
    }
    else {
        $fakeDot = Join-Path $binDir 'dot'
        Set-Content -Path $fakeDot -Value "#!/bin/sh`necho ""ARG:`$1"""
        chmod +x $fakeDot
    }

    $dotFile = Join-Path $TestDrive 'my graph.dot'
    Set-Content -Path $dotFile -Value 'digraph { a -> b }'
}

Describe 'Invoke-DOTExecutable' {
    It 'runs Graphviz with the call operator when paths contain spaces' {
        $output = InModuleScope AzViz -Parameters @{ Dot = $fakeDot; File = $dotFile } {
            Invoke-DOTExecutable -GraphViz $Dot -Path $File
        }

        $output | Should -Be "ARG:$dotFile"
    }

    It 'throws when Graphviz exits with a non-zero code' {
        $failingDot = if ($IsWindows) { Join-Path $binDir 'fail.cmd' } else { Join-Path $binDir 'fail' }
        if ($IsWindows) {
            Set-Content -Path $failingDot -Value '@exit /b 3'
        }
        else {
            Set-Content -Path $failingDot -Value "#!/bin/sh`nexit 3"
            chmod +x $failingDot
        }

        {
            InModuleScope AzViz -Parameters @{ Dot = $failingDot; File = $dotFile } {
                Invoke-DOTExecutable -GraphViz $Dot -Path $File
            }
        } | Should -Throw '*exit code 3*'
    }
}
