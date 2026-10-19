BeforeDiscovery {
    $workflowRoot = Join-Path (Split-Path $PSScriptRoot -Parent) '.github' 'workflows'
    $workflows = Get-ChildItem $workflowRoot -Include *.yml, *.yaml -Recurse |
        ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
}

Describe 'Workflow <Name>' -ForEach $workflows {
    BeforeAll {
        $lines = Get-Content -Path $Path
    }

    It 'pins every action to a full commit SHA' {
        $lines | Where-Object { $_ -match '^\s*-?\s*uses:\s*(\S+)' } |
            ForEach-Object { ($_ -replace '^\s*-?\s*uses:\s*', '' -split '\s')[0] } |
            Where-Object { $_ -notmatch '^\./' -and $_ -notmatch '@[0-9a-f]{40}$' } |
            Should -BeNullOrEmpty
    }

    It 'does not dump environment variables' {
        $lines | Where-Object { $_ -match 'Get-ChildItem\s+(-Path\s+)?env:|\bprintenv\b|^\s*-?\s*run:\s*env\s*$' } |
            Should -BeNullOrEmpty
    }

    It 'declares least-privilege permissions' {
        $lines | Should -Contain 'permissions:'
        ($lines -join "`n") | Should -Match 'permissions:\s*\n\s+contents:\s*read'
    }
}

Describe 'Publish workflow' {
    BeforeAll {
        $publish = Get-Content -Raw (Join-Path $PSScriptRoot '..' '.github' 'workflows' 'publish.yml')
    }

    It 'runs only for published releases' {
        $publish | Should -Match 'release:\s*\n\s+types:\s*\[\s*published\s*\]'
        $publish | Should -Not -Match 'head_commit\.message'
    }

    It 'is gated by the protected psgallery environment' {
        $publish | Should -Match 'environment:\s*\n\s+name:\s*psgallery'
    }

    It 'publishes with PSResourceGet' {
        $publish | Should -Match 'Publish-Module\.ps1'
        Get-Content -Raw (Join-Path $PSScriptRoot '..' 'build' 'Publish-Module.ps1') | Should -Match 'Publish-PSResource'
    }
}
