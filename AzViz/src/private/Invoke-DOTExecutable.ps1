function Invoke-DOTExecutable {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory)]
        [string] $GraphViz,

        [Parameter(Mandatory)]
        [string] $Path
    )

    # The call operator passes each argument as-is on every platform, so paths
    # containing spaces need no extra quoting.
    & $GraphViz $Path
    if ($LASTEXITCODE -ne 0) {
        throw "Graphviz '$GraphViz' failed with exit code $LASTEXITCODE while processing '$Path'."
    }
}
