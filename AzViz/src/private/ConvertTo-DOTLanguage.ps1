function ConvertTo-DOTLanguage {
    [CmdletBinding()]
    param (
        [string[]] $Targets,
        [ValidateSet('Azure Resource Group')]
        [string] $TargetType = 'Azure Resource Group',
        [int] $LabelVerbosity = 1,
        [int] $CategoryDepth = 1,
        [string] $Direction = 'top-to-bottom',
        [string] $Splines = 'spline',
        [string[]] $ExcludeTypes,
        [ValidateSet('light', 'dark', 'neon')]
        [string] $Theme = 'light'
    )
    
    begin {
        $Colors = Get-ThemeColor -Theme $Theme
        switch ($Direction) {
            'left-to-right' { $rankdir = "LR" }
            'top-to-bottom' { $rankdir = "TB" }
        }
    }
    
    process {

        $null = Test-AzLogin
        
        $SpecialChars = '() []{}&-.'
        $GraphObjects = @()
        $NetworkObjects = ConvertFrom-Network -TargetType $TargetType -Targets $Targets -CategoryDepth $CategoryDepth -ExcludeTypes $ExcludeTypes
        $GraphObjects += $NetworkObjects
        $ARMObjects = ConvertFrom-ARM -TargetType $TargetType -Targets $Targets -CategoryDepth $CategoryDepth -ExcludeTypes $ExcludeTypes
        $GraphObjects += $ARMObjects

        $GraphObjects = $GraphObjects | 
        Group-Object Name | 
        ForEach-Object {
            [PSCustomObject]@{
                Name      = $_.Name
                Type      = $_.group.type | Select-Object -First 1
                Resources = $_.group.Resources
            }
        } | 
        Sort-Object Rank
        
        $Counter = 0
        $subgraphs = foreach ($Target in $GraphObjects) {
            $Counter = $Counter + 1              
            Write-CustomHost "Plotting sub-graph for $($Target.Type): `"$($Target.Name)`"" -Indentation 1 -AddTime

            $VNets = Get-AzVirtualNetwork -ResourceGroupName $Target.Name -Verbose:$false
            $NetworkLayout = @()
            if ($VNets) {
                
                $VNetCounter = 0
                $VMs_and_NICs = @()
                $VMs = Get-AzVM -ResourceGroupName $Target.Name -Verbose:$false
                $NICs = Get-AzNetworkInterface -ResourceGroupName $Target.Name -Verbose:$false
                $VMs_and_NICs += $VMs
                $VMs_and_NICs += $NICs
                
                foreach ($vnet in $VNets) {
                    
                    $VNetCounter = $VNetCounter + 1

                    $VNetLabel = Get-ImageLabel -Type "Microsoft.Network/virtualNetworks" -Row1 "$($VNet.Name)" -Row2 "$([string]$VNet.AddressSpace.AddressPrefixes)"
                    $VNetSubGraphName = Remove-SpecialChar -String $VNet.Name -SpecialChars $SpecialChars
                    $VNetSubGraphAttributes = @{
                        label    = $VNetLabel;
                        labelloc = 't';
                        penwidth = "1";
                        fontname = "Courier New" ;
                        style    = "rounded,dashed";
                        color    = $Colors.VNetGraphColor
                        bgcolor  = $Colors.VNetGraphBGColor
                    }
    
                    # generating dot language for virtual networks and then iterating all the subnets
                    $NetworkLayout += SubGraph -Name $VNetSubGraphName -Attributes $VNetSubGraphAttributes -ScriptBlock {
                        $Subnets = $VNet.Subnets

                        # if there a no subnets in a virtual network, then plot empty vNet
                        # if(!$Subnets){ 

                        # }
                        # else{
                        foreach ($subnet in $Subnets) {
    
                            $SubnetLabel = Get-ImageLabel -Type "Subnets" -Row1 "$($Subnet.Name)" -Row2 "$([string]$Subnet.AddressPrefix)"
                            $SubnetSubGraphName = Remove-SpecialChar -String $Subnet.Name -SpecialChars $SpecialChars
                            $SubnetSubGraphAttributes = @{
                                label    = $SubnetLabel;
                                labelloc = 't';
                                penwidth = "1";
                                fontname = "Courier New" ;
                                style    = "rounded,dashed";
                                color    = $Colors.SubnetGraphColor
                                bgcolor  = $Colors.SubnetGraphBGColor; 
                            }
    
                            # generating dot language for subnets inside virtual networks    
                            SubGraph -Name $SubnetSubGraphName -Attributes $SubnetSubGraphAttributes -ScriptBlock {    
                                $resources_in_subnet = foreach ($item in $VMs_and_NICs) {
                                    switch ($item.Type) {
                                        'Microsoft.Compute/virtualMachines' {
                                            $networkInterface = $NICs.Where( { $_.name -eq ($item.NetworkProfile.NetworkInterfaces[0].Id.Split('/')[-1]) })
                                            $subnetName = $networkInterface.IpConfigurations[0].Subnet.Id.split('/')[-1] 
                                        }
                                        'Microsoft.Network/networkInterfaces' {
                                            $subnetName = $item.IpConfigurations[0].Subnet.Id.split('/')[-1] 
                                        }
                                    }
        
                                    if ($subnetName -eq $subnet.Name) {
                                        $item | Select-Object Name, Type
                                    }
                                }
        
                                $resources_in_subnet |
                                ForEach-Object {
                                    Get-ImageNode -Name "$($_.Type)/$($_.Name)".tolower() -Rows $_.Name -Type $_.Type
                                }
                            }
                        }
                        # }

                    }
                }
            }

            #region plotting-edges-to-nodes
            $Resources = $Target.Resources
            if ($Resources) {
                # $NodesAndEdges = $Resources |
                $nodes = @()
                $edges = @()

                $Resources |
                Tee-Object -Variable pipe_var |
                ForEach-Object {
                    $from = $_.from
                    $fromcateg = $_.fromcateg
                    $to = $_.to
                    $tocateg = $_.tocateg
                    if ($_.isdependent) {
                        $edges += Edge -From "$fromcateg/$from".tolower() `
                                        -to "$tocateg/$to".tolower() `
                                        -Attributes @{
                                            arrowhead = 'normal';
                                            style     = 'dashed';
                                            # label     = 'dependsOn'
                                            penwidth  = "1"
                                            fontname  = "Courier New"
                                            color     = $Colors.DependencyEdgeColor
                                        }
    
                        if ($LabelVerbosity -eq 1) {
                            $nodes += Get-ImageNode -Name "$fromcateg/$from".tolower() -Rows $from -Type $fromcateg -ErrorAction SilentlyContinue
                            $nodes += Get-ImageNode -Name "$tocateg/$to".tolower() -Rows $to -Type $tocateg -ErrorAction SilentlyContinue
                        }
                        elseif ($LabelVerbosity -eq 2) {
                            $nodes += Get-ImageNode -Name "$fromcateg/$from".tolower() -Rows ($from, $fromcateg) -Type $fromcateg -ErrorAction SilentlyContinue
                            $nodes += Get-ImageNode -Name "$tocateg/$to".tolower() -Rows ($to, $toCateg) -Type $tocateg -ErrorAction SilentlyContinue
                        }
                    }
                    if ($_.association) {
                        $edges += Edge -From "$fromcateg/$from".tolower() `
                            -to "$tocateg/$to".tolower() `
                            -Attributes @{
                            arrowhead = 'normal';
                            style     = 'solid';
                            penwidth  = "1"
                            fontname  = "Courier New"
                            color     = $Colors.NetworkEdgeColor
                        }
    
                        if ($LabelVerbosity -eq 1) {
                            $nodes += Get-ImageNode -Name "$fromcateg/$from".tolower() -Rows $from -Type $fromcateg -ErrorAction SilentlyContinue
                            $nodes += Get-ImageNode -Name "$tocateg/$to".tolower() -Rows $to -Type $tocateg -ErrorAction SilentlyContinue
                        }
                        elseif ($LabelVerbosity -eq 2) {
                            $nodes += Get-ImageNode -Name "$fromcateg/$from".tolower() -Rows ($from, $fromcateg) -Type $fromcateg -ErrorAction SilentlyContinue

                            # If this resource is a network association, it may not have the $toCateg defined, so it will be null.
                            # This will fail inside Get-ImageNode when its trying to split and format the string
                            if ([String]::IsNullOrEmpty($tocateg)) {
                                $nodes += Get-ImageNode -Name "$tocateg/$to".tolower() -Rows $to -Type $tocateg -ErrorAction SilentlyContinue
                            } else {
                                $nodes += Get-ImageNode -Name "$tocateg/$to".tolower() -Rows ($to, $toCateg) -Type $tocateg -ErrorAction SilentlyContinue
                            }
                        }
                    }
                    else {
                        if ($LabelVerbosity -eq 1) {
                            $nodes += Get-ImageNode -Name "$fromcateg/$from".tolower() -Rows $from -Type $fromcateg -ErrorAction SilentlyContinue
                        }
                        elseif ($LabelVerbosity -eq 2) {
                            $nodes += Get-ImageNode -Name "$fromcateg/$from".tolower() -Rows ($from, $fromcateg) -Type $fromcateg -ErrorAction SilentlyContinue
                        }
                    }
                } | 
                Select-Object -Unique

                if($nodes){

                    Write-CustomHost -String "Creating Nodes" -Indentation 2

                    $nodes |
                    Select-Object -Unique | 
                    ForEach-Object {
                        Write-CustomHost -String $($_.split(" ")[0].Replace('"','')) -Indentation 3
                    } 
                }

                if($edges){

                    Write-CustomHost -String "Creating Edges" -Indentation 2

                    $edges |
                    Select-Object -Unique | 
                    ForEach-Object {
                        $first, $second = $_.split(" ")[0].Replace('"','').split("->")
                        if($first -and $second){
                            Write-CustomHost -String "$first -> $second" -Indentation 3
                        }
                    }
                }

                $NodesAndEdges = $nodes + $edges
            }

            if ($Resources -or $VNets) {
                $ResourceGroupLocation = (Get-AzResourceGroup -Name $Target.Name -Verbose:$false).Location
                $ResourceGroupSubGraphName = [string]::Concat($(Remove-SpecialChar -String $Target.Name -SpecialChars $SpecialChars), $Counter)
                $ResourceGroupSubGraphNameLabel = Get-ImageLabel -Type "ResourceGroups" -Row1 "ResourceGroup: $(Remove-SpecialChar -String $Target.name -SpecialChars $SpecialChars)" -Row2 "Location: $($ResourceGroupLocation)"
                $ResourceGroupSubGraphAttributes = @{
                    label    = $ResourceGroupSubGraphNameLabel;
                    labelloc = 't';
                    penwidth = "1";
                    fontname = "Courier New" ;
                    style    = "rounded, dashed";
                    color    = $Colors.ResourceGroupGraphColor;
                    bgcolor  = $Colors.ResourceGroupGraphBGColor;
                    fontsize = "9"; 
                }

                SubGraph -Name $ResourceGroupSubGraphName -Attributes $ResourceGroupSubGraphAttributes -ScriptBlock {
                    $NetworkLayout
                    $NodesAndEdges
                }
            } else {
                Write-CustomHost -String "No resources found.. re-run the command and try increasing the category depth using -CategoryDepth 2 or -CategoryDepth 3 cmdlet parameters." -Indentation 1 -AddTime
            }
            #endregion plotting-edges-to-nodes
        }

        $Legend = @()
        $Legend += '    subgraph clusterLegend {'
        $Legend += '        label = "Legend\n\n";'
        $Legend += '        rank = 9999999999999'
        $Legend += '        clusterrank=local'
        $Legend += '        bgcolor = {0}' -f $Colors.MainGraphBGColor
        $Legend += '        fontcolor = {0}' -f $Colors.EdgeFontColor
        $Legend += '        fontsize = 11'
        $Legend += '        node [shape=point]'
        $Legend += '        {'
        $Legend += '            rank=same'
        $Legend += '            d0 [style = invis];'
        $Legend += '            d1 [style = invis];'
        $Legend += '            p0 [style = invis];'
        $Legend += '            p1 [style = invis];'
        $Legend += '        }'
        $Legend += '        d0 -> d1 [arrowhead="normal";style="dashed";label="Resource\nDependency";color="{0}";fontname="Courier New";penwidth="1";fontsize="9";fontcolor="{1}"]' -f $Colors.DependencyEdgeColor, $Colors.EdgeFontColor
        $Legend += '        p0 -> p1 [style="solid";fontname="Courier New";label="Network\nAssociation";arrowhead="normal";color="{0}";penwidth="1";fontsize="9";fontcolor="{1}"]' -f $Colors.NetworkEdgeColor, $Colors.EdgeFontColor
        $Legend += '    }'



        if ($subgraphs) {
            $Subscription = (Get-AzContext).Subscription
            $VisualizationAttributes = @{
                rankdir   = $rankdir
                overlap   = 'false'
                splines   = $Splines 
                color     = $Colors.VisualizationGraphColor
                bgcolor   = $Colors.VisualizationGraphColor
                penwidth  = "1"
                fontname  = "Courier New" 
                fontcolor = $Colors.GraphFontColor
                fontsize  = "9"
            }

            $graph = Graph -Name 'Visualization' -Attributes $VisualizationAttributes -ScriptBlock {
                
                $MainGraphLabel = Get-ImageLabel -Type "Subscriptions" -Row1 "Subscription: $(Remove-SpecialChar -String $Subscription.name -SpecialChars $SpecialChars)" -Row2 "Id: $($Subscription.Id)"
                $MainGraphAttributes = @{
                    label    = $MainGraphLabel
                    fontsize = "9"
                    style    = "rounded,solid"
                    bgcolor  = $Colors.MainGraphBGColor
                }

                SubGraph -Name 'main' -Attributes $MainGraphAttributes -ScriptBlock {
            
                    edge @{color = $Colors.EdgeColor; fontcolor = $Colors.EdgeFontColor; fontsize = "11" }
                    node @{color = $Colors.NodeColor ; fontcolor = $Colors.NodeFontColor; fontsize = "11" }
                
                    $subgraphs
                }
                
                # graph legends only appear if edges exist between the nodes
                # legends for now only represent the edges in the graph and if there are no edges there is no point showing legends in the graph
                if ($edges){
                    $Legend
                }
            }

            # hack to fix issue because of double-quotes in image labels
            $graph = $graph | ForEach-Object {
                if ($_ -like '*"<<TABLE*') {
                    $_.replace('"', '')
                }
                else {
                    $_
                }
            } 

            # to indent and validate the dot language generated by powershell
            $GraphViz = Get-DOTExecutable
            $dot_file = New-TemporaryFile
            try {
                $graph | Out-String | Out-File $dot_file -Verbose:$false -Encoding ascii
                Invoke-DOTExecutable -GraphViz $GraphViz.FullName -Path $dot_file.FullName
            }
            finally {
                Remove-Item $dot_file -Force -ErrorAction SilentlyContinue
            }

        }
    }
    
    end {
        
    }
}
