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

    if($params.count -gt 1){
        return $null
    }

    $branchName = ""

    if(1 -eq $params.count){
        $branchName = $params[0]
    }

    if($branchName.StartsWith("-")){
        return $null
    }

    $selectedBranch = $null
    $nl = "`r`n"
    $green = $colors.green
    $white = $colors.white
    $red = $colors.red
    $currentBranchName = (Get-Current-BranchName)

    $branches = (Get-Git-Branches-Complex -includehead $commandConfig.includeHead -showAll $True -remote $False)

    $matchedBranches = [System.Object[]](Get-Matching-Branches -branchName $branchName -branches $branches)

    if(0 -eq $matchedBranches.length){
        Write-Host "${red}No suitable matching branch was found"
        return ""
    }

    if($matchedBranches.length -eq 1){
        $selectedBranch = $matchedBranches[0]
    }elseif($matchedBranches.length -gt 1){
        Write-Host "You are currently on branch ${green}'${currentBranchName}'${white}.${nl}Please use the arrow keys and press enter to select another branch."

        $menu = (New-InteractiveMenu-BranchItem -matchedBranches $matchedBranches -branchTypes $branchTypes)

        $menuSelection = (New-InteractiveMenu -itemsList @($menu) -numberOfHeaderLines 2)
        if($null -eq $menuSelection){
            Write-Host "No branch was selected"
            return ""
        }
        $selectedBranch = $matchedBranches[$menuSelection]
    }
    
    $selectedBranchHasRemote = $selectedBranch.isRemote
    $branchName = $selectedBranch.name

    . git checkout $branchName
    if($commandConfig.pullAfterCheckout -and $selectedBranchHasRemote){
        Write-Host "Pulling changes..."
        $pr = (git pull 2>&1)
        Write-Host $pr
    }
    
    return ""
}