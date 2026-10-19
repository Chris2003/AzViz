function Test-AzLogin {
    [CmdletBinding()]
    [OutputType([boolean])]
    param()

    # Never prompt: an interactive Connect-AzAccount would hang unattended runs.
    $message = 'Not signed in to Azure. Run Connect-AzAccount (interactively, or with a service principal, ' +
        'managed identity or federated token) before running AzViz.'

    Write-Verbose 'Testing Azure login'
    try {
        $context = Get-AzContext -ErrorAction Stop
    }
    catch {
        throw "$message $($_.Exception.Message)"
    }

    if (-not $context) {
        throw $message
    }

    $true
}
