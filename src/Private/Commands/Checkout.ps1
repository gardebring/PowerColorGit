function Get-Command-Checkout {
    param(
        [Parameter(Mandatory = $true)]
        [string]$directory,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$params,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$config
    )

    $commandConfig = $config.commands.checkout
    $branchTypes = $config.commands.branch.branchTypes

    if(1 -ne $params.count){
        return $null
    }

    $branchName = $params[0]
    
    if($branchName.StartsWith("-")){
        return $null
    }

    $branches = (Get-Git-Branches-Complex -includehead $commandConfig.includeHead  -showAll $True -remote $False)

    $matchedBranches = @()
    $selectedBranchIndex = -1
    $nl = "`r`n"
    $index = 0
    $green = $colors.green
    $white = $colors.white
    $currentBranchName = $null

    foreach ($branch in $branches["branchName"]) {
        $isCurrent = $branches["isCurrent"][$index]
        $isLocal = $branches["isLocal"][$index]
        $isRemote = $branches["isRemote"][$index]

        $bn = $branch

        if($isCurrent){
            $currentBranchName = $bn
        }

        if($bn -eq $branchName){
            if($isCurrent){
                Write-Host "Already on branch ${green}'${bn}'."
                return ""
            }
            $selectedBranchIndex = $index
            break;
        }elseif($bn.Contains($branchName, "CurrentCultureIgnoreCase") -and -not $isCurrent){
            $matchedBranches += $index
        }
        $index++
    }

    if(-1 -eq $selectedBranchIndex -and 0 -eq $matchedBranches.length){
        Write-Host "No matching branch was found"
        return ""
    }

    if($matchedBranches.length -eq 1){
        $selectedBranchIndex = $matchedBranches[0]
    }elseif($matchedBranches.length -gt 1){
        Write-Host "You are currently on branch ${green}'${currentBranchName}'${white}.${nl}Please use the arrow keys and press enter to select another branch."
        $menu = @()
        foreach ($index in $matchedBranches) {
            $isLocal = $branches["isLocal"][$index]
            $isRemote = $branches["isRemote"][$index]
            $bn = $branches["branchName"][$index]

            $menuItem = ""

            if($isLocal){
                $menuItem = -join($menuItem, $symbols.house, " ")
            }else{
                $menuItem = -join($menuItem, "  ")
            }

            if($isRemote){
                $menuItem = -join($menuItem, $symbols.globe, " ")
            }else{
                $menuItem = -join($menuItem, "  ")
            }

            $menuItem = -join($menuItem, (Get-Branch-Icon -branchName $bn -branchTypes $branchTypes -glyphs $glyphs -setIconColor $false)," ")

            $menuItem = -join($menuItem, $bn)

            $menu += $menuItem
        }

        $menuSelection = (New-InteractiveMenu -itemsList @($menu))
        if($null -eq $menuSelection){
            Write-Host "No branch was selected"
            return ""
        }
        $selectedBranchIndex = $matchedBranches[$menuSelection]
    }
    
    $selectedBranchHasRemote = $branches["isRemote"][$selectedBranchIndex]
    $branchName = $branches["branchName"][$selectedBranchIndex]

    . git checkout $branchName
    if($commandConfig.pullAfterCheckout -and $selectedBranchHasRemote){
        Write-Host "Pulling changes..."
        $pr = (git pull)
        Write-Host $pr
    }

    return ""
}