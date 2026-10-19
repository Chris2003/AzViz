function Get-ThemeColor {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [ValidateSet('light', 'dark', 'neon')]
        [string] $Theme = 'light'
    )

    switch ($Theme) {
        'light' {
            @{
                VisualizationGraphColor   = 'White'
                MainGraphBGColor          = 'ivory1'
                ResourceGroupGraphColor   = 'black'
                ResourceGroupGraphBGColor = 'ghostwhite'
                VNetGraphColor            = 'mintcream'
                SubnetGraphBGColor        = 'whitesmoke'
                SubnetGraphColor          = 'black'
                GraphFontColor            = 'black'
                DependencyEdgeColor       = 'lightslategrey'
                NetworkEdgeColor          = 'royalblue2'
                EdgeFontColor             = 'black'
                NodeColor                 = 'black'
                NodeFontColor             = 'black'
            }
        }
        'dark' {
            @{
                VisualizationGraphColor   = 'White'
                MainGraphBGColor          = 'Black'
                ResourceGroupGraphColor   = 'white'
                ResourceGroupGraphBGColor = 'grey7'
                VNetGraphColor            = 'white'
                VNetGraphBGColor          = 'grey15'
                SubnetGraphColor          = 'white'
                SubnetGraphBGColor        = 'grey23'
                GraphFontColor            = 'white'
                DependencyEdgeColor       = 'lightslategrey'
                NetworkEdgeColor          = 'royalblue2'
                EdgeFontColor             = 'white'
                NodeColor                 = 'white'
                NodeFontColor             = 'white'
            }
        }
        'neon' {
            @{
                VisualizationGraphColor   = 'White'
                MainGraphBGColor          = 'grey14'
                ResourceGroupGraphColor   = 'white'
                ResourceGroupGraphBGColor = 'midnightblue'
                VNetGraphColor            = 'white'
                VNetGraphBGColor          = 'darkslategray'
                SubnetGraphColor          = 'white'
                SubnetGraphBGColor        = 'maroon4'
                GraphFontColor            = 'gold2'
                DependencyEdgeColor       = 'olivedrab1'
                NetworkEdgeColor          = 'lightpink2'
                EdgeFontColor             = 'gold2'
                NodeColor                 = 'gold2'
                NodeFontColor             = 'gold2'
            }
        }
    }
}
