BeforeDiscovery {
    $moduleRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'AzViz'
    $scripts = Get-ChildItem $moduleRoot -Include *.ps1, *.psm1, *.psd1 -Recurse |
        ForEach-Object { @{ Name = $_.Name; Path = $_.FullName } }
}

Describe 'PSScriptAnalyzer' -Tag Build {
    It '<Name> has no Warning or Error findings' -ForEach $scripts {
        $results = Invoke-ScriptAnalyzer -Path $Path -Severity Warning, Error
        $results | ForEach-Object { '{0} line {1}: {2}' -f $_.RuleName, $_.Line, $_.Message } |
            Should -BeNullOrEmpty
    }
}
