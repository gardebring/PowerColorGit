function Get-Command-Branch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$directory,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$params,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$config
    )

    $commandConfig = $config.commands.branch

    # Start internal functions   

    function Get-Options{
        param(
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$params
        )

        $options = @{
            showAll = $false
            remote = $false
            deleteFullyMergedBranch = $false
            deleteNotMergedBranch = $false
            force = $false
            branchName = $null
        }

        foreach ($param in $params) {
            if($null -ne $param){
                $p = "$param".Trim()
                switch ($p) {
                    {(($p -eq "-a") -or ($p -eq "-all"))} {
                        $options.showAll = $true
                        break
                    }
                    {(($p -eq "-d") -or ($p -eq "--delete"))} {
                        $options.deleteFullyMergedBranch = $true
                        break
                    }
                    {(($p -eq "-f") -or ($p -eq "--force"))} {
                        $options.force = $true
                        break
                    }                    
                    {(($p -eq "-D"))} {
                        $options.deleteNotMergedBranch = $true
                        break
                    }                    
                    {(($p -eq "-r") -or ($p -eq "-remotes"))} {
                        $options.remote = $true
                        break
                    }
                    {((-not $p.StartsWith("-")))} {
                        $options.branchName = $param
                        break
                    }                    
                    default{
                        return $null;
                    }
                }
            }
        }

        if($options.deleteFullyMergedBranch -and $options.force -and (-not $options.deleteNotMergedBranch)){
            $options.deleteNotMergedBranch = $true
        }

        return $options
    }
    # End internal functions

    $options = (Get-Options -params $params)

    if(($null -eq $options) -or ($options.showAll -and $options.deleteFullyMergedBranch) -or ($options.showAll -and $options.deleteNotMergedBranch)){
        return $null
    }

    $branchTypes = $commandConfig.branchTypes

    $showAll = $options.showAll -or $options.deleteNotMergedBranch -or $options.deleteFullyMergedBranch
    $branches = (Get-Git-Branches-Complex -includehead $commandConfig.showHead -showAll $showAll -remote $options.remote)

    $output = ""
    $nl = "`r`n"
    $green = $colors.green
    $white = $colors.white
    $red = $colors.red    

    if($options.deleteFullyMergedBranch -or $options.deleteNotMergedBranch){
        $branchName = $options.branchName
        $currentBranchName = (Get-Current-BranchName)
        $selectedBranch = $null
        $matchedBranches = [System.Object[]](Get-Matching-Branches -branchName $branchName -branches $branches)
        if(0 -eq $matchedBranches.length){
            Write-Host "${red}No suitable matching branch was found"
            return ""
        }
        if($matchedBranches.length -eq 1){
            $selectedBranch = $matchedBranches[0]
        }elseif($matchedBranches.length -gt 1){
            Write-Host "You are currently on branch '${green}${currentBranchName}${white}'.${nl}Please use the arrow keys and press enter to select what branch to ${red}delete!"
    
            $menu = (New-InteractiveMenu-BranchItem -matchedBranches $matchedBranches -branchTypes $branchTypes)
    
            $menuSelection = (New-InteractiveMenu -itemsList @($menu) -numberOfHeaderLines 2 -activeColor $colors.red)
            if($null -eq $menuSelection){
                Write-Host "No branch was selected"
                return ""
            }
            $selectedBranch = $matchedBranches[$menuSelection]
        }
        
        $branchName = $selectedBranch.name
       
        if($selectedBranch.isLocal){
            do {
                $response = Read-Host -Prompt "${white}Do you want to ${red}delete ${white}the local branch '${red}${branchName}${white}'? [Y/N]"
                if ($response -eq "y") {
                    Write-Host "${white}Deleting local branch '${red}${branchName}${white}'..."
                    if($options.deleteNotMergedBranch){
                        . git branch $branchName -D
                    }elseif($options.deleteFullyMergedBranch){
                        . git branch $branchName -d 
                    }
                }
            } until ($response -eq "n" -or $response -eq "y") 
        }
        if($response -eq "n"){
            Write-Host "Operation aborted"
        }

        if($selectedBranch.isRemote){
            do {
                $response = Read-Host -Prompt "${white}Do you want to ${red}delete ${white}the remote branch '${red}${branchName}${white}'? [Y/N]"
                if ($response -eq "y") {
                    $origin = Get-Origin
                    $gp = (git push $origin --delete $branchName 2>&1)
                    Write-Host $gp
                    #. git push $origin --delete $branchName
                    return ""
                }
            } until ($response -eq "n")             
        }

        Write-Host "Operation aborted"

        return ""
    }

    foreach($branch in $branches){
        $color = $colors.white

        if($branch.isCurrent){
            $color = $colors.green
        }elseif($branch.isLocal){
            $color = $colors.white
        }elseif($branch.isRemote){
            $color = $colors.brightRed
        }
        
        $output = -join($output, $color)

        if($branch.isCurrent){
            $output = -join($output, $symbols.check, " ")
        }else{
            $output = -join($output, "  ")
        }

        if($branch.isLocal){
            $output = -join($output, $emojis.house, "")
        }else{
            $output = -join($output, "  ")
        }
        
        if($branch.isRemote){
            $output = -join($output, $emojis.globe, "")
        }else{
            $output = -join($output, "  ")
        }

        $output = -join($output, (Get-Branch-Icon -branchName $branch.name -branchTypes $branchTypes -glyphs $glyphs -setIconColor $true), $color, " ")

        $output = -join($output, $branch.name, $nl)
    }
  
    return $output
}

