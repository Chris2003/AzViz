function Get-DOTExecutable {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param()

    $PossibleGraphVizPaths = @(
        'C:\Program Files\NuGet\Packages\Graphviz*\dot.exe',
        'C:\program files*\GraphViz*\bin\dot.exe',
        '/usr/local/bin/dot',
        '/usr/bin/dot',
        '/opt/homebrew/bin/dot'
    )
    $PossibleGraphVizPaths += (Get-Command -CommandType Application -Name dot -ErrorAction SilentlyContinue).Source

    $GraphViz = Resolve-Path -Path ($PossibleGraphVizPaths | Where-Object { $_ }) -ErrorAction SilentlyContinue |
        Get-Item |
        Where-Object BaseName -eq 'dot' |
        Select-Object -First 1

    if ($null -eq $GraphViz) {
        throw "Graphviz is not installed or 'dot' could not be found on PATH. Graphviz is required to render diagrams. " +
            "Install it from https://graphviz.org/download/ (for example 'winget install Graphviz.Graphviz', " +
            "'brew install graphviz' or 'sudo apt-get install graphviz') and re-run this command."
    }

    return $GraphViz
}
