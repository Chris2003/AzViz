<#
.SYNOPSIS
Exports one diagram per resource group for every subscription the signed-in account can see.

.DESCRIPTION
Iterates every subscription returned by Get-AzSubscription, selects it, and calls Export-AzViz
for each resource group. Diagrams are written to <OutputFilePath>/<MM-dd-yyyy>/<subscription>/<resource group>.<format>.

.PARAMETER Theme
Color theme passed to Export-AzViz: 'light', 'dark' or 'neon'.

.PARAMETER OutputFilePath
Root directory for the generated diagrams.

.PARAMETER LabelVerbosity
Level of information included in the visualization.

.PARAMETER CategoryDepth
Level of Azure resource sub-category included in the visualization.

.PARAMETER OutputFormat
Output format of the visualization, 'png' or 'svg'.

.PARAMETER Direction
Direction in which resource groups are plotted.

.EXAMPLE
Export-AzVizTenant -Theme light -OutputFilePath ./diagrams

.NOTES
Based on https://www.reddit.com/r/PowerShell/comments/mmxq6a/powershell_module_to_visualize_and_document_azure/gtwb6uf
#>
function Export-AzVizTenant {
    [CmdletBinding()]
    [Alias('Get-TenantDiagrams')]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('light', 'dark', 'neon')]
        [string] $Theme,

        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path -Path $_ -IsValid })]
        [string] $OutputFilePath,

        [ValidateSet(1, 2, 3)]
        [int] $LabelVerbosity = 1,

        [ValidateSet(1, 2, 3)]
        [int] $CategoryDepth = 1,

        [ValidateSet('png', 'svg')]
        [string] $OutputFormat = 'png',

        [ValidateSet('left-to-right', 'top-to-bottom')]
        [string] $Direction = 'left-to-right'
    )

    $DateFolder = Get-Date -Format MM-dd-yyyy

    foreach ($Subscription in Get-AzSubscription) {
        $null = Set-AzContext -SubscriptionId $Subscription.Id
        $SubscriptionFolder = Join-Path $OutputFilePath $DateFolder $Subscription.Name
        $null = New-Item -Path $SubscriptionFolder -ItemType Directory -Force

        foreach ($ResourceGroup in Get-AzResourceGroup) {
            $Params = @{
                ResourceGroup  = $ResourceGroup.ResourceGroupName
                OutputFilePath = Join-Path $SubscriptionFolder "$($ResourceGroup.ResourceGroupName).$OutputFormat"
                Theme          = $Theme
                OutputFormat   = $OutputFormat
                CategoryDepth  = $CategoryDepth
                Direction      = $Direction
                LabelVerbosity = $LabelVerbosity
            }

            # One failing resource group should not stop the rest of the tenant export.
            try {
                Export-AzViz @Params
            }
            catch {
                Write-Error -ErrorRecord $_
            }
        }
    }
}
