function Write-CustomHost {
    [CmdletBinding()]
    param (
        [String] $String,
        [string] $StartChar = [char]9654,
        [int] $Indentation = 1,
        [switch] $AddTime
    )

    $Message = '{0} {1} {2}' -f ('   ' * $Indentation), $StartChar, $String

    if ($AddTime -and $script:AzVizStartTime) {
        $TimeDelta = [datetime]::Now - $script:AzVizStartTime
        if ($TimeDelta.TotalSeconds -ge 60) {
            $Duration = "{0}m {1}s" -f $TimeDelta.Minutes, $TimeDelta.Seconds
        }
        elseif ($TimeDelta.TotalSeconds -gt 1) {
            $Duration = "{0:n2}s" -f $TimeDelta.TotalSeconds
        }
        else {
            $Duration = "{0}ms" -f [int]$TimeDelta.TotalMilliseconds
        }
        $Message = "$Message $Duration"
    }

    # Progress goes to the information stream so callers can silence, capture
    # (-InformationVariable) or show it (-InformationAction Continue).
    Write-Information -MessageData $Message -Tags 'AzViz'
}
