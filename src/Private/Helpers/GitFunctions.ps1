function Get-IsGitDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$directory
    )

    if ((Test-Path "${directory}/.git") -eq $TRUE) {
        return $TRUE
    }

    # Test within parent dirs
    $checkIn = (Get-Item ${directory}).parent
    while ($null -ne $checkIn) {
        $pathToTest = $checkIn.FullName + '/.git'
        if ((Test-Path $pathToTest) -eq $TRUE) {
            return $TRUE
        } else {
            $checkIn = $checkIn.parent
        }
    }

    return $FALSE
}

function Get-Git-Branches {
    git branch -a
}

function Get-Current-BranchName {
    git branch --show-current
}

function Get-Git-Branches-Complex {
    param(
        [Parameter(Mandatory = $true)]
        [Boolean]$includeHead,

        [Parameter(Mandatory = $true)]
        [Boolean]$showAll,
        
        [Parameter(Mandatory = $true)]
        [Boolean]$remote        
    )

    $availableBranches = Get-Git-Branches | ConvertFrom-String -propertyNames isCurrent, branch

    $branchList = @()
    
    $remotesLikePattern = "*remotes/*"

    foreach($branch in $availableBranches){
        $isCurrent = $branch.isCurrent -eq "*"
        $isRemote = $branch.branch -like($remotesLikePattern)
        $isLocal = $branch.branch -notlike($remotesLikePattern)
        $addCurrent = $True
        $index = 0;

        foreach($addedBranch in $branchList){
            $bn = $addedBranch.name
            $c = $branch.branch -like("*$bn*") -and $branch.branch -like($remotesLikePattern)
            if($c){
                $addedBranch.isRemote = $isRemote
                $addCurrent = $false
                break
            }
            $index += 1
    	}
        
        $branchName = $branch.branch -replace("remotes/origin/", "")

        if(("HEAD" -eq $branchName) -and (-not $includeHead)){
            $addCurrent = $false
        }

        if($addCurrent){
            if($isRemote -and (-not $showAll)-and (-not $remote)){
                $addCurrent = $false
            }
            if($isLocal -and ($remote)){
                $addCurrent = $false
            }
        }

        if($addCurrent ){

            $branch = @{
                name = $branchName
                isCurrent = $isCurrent
                isRemote = $isRemote
                isLocal = $isLocal
            }
            
            $branchList += $branch            
        }
      }
      
      return $branchList
}

function Get-Is-Branch-Type{
    param(
        [Parameter(Mandatory = $true)]
        [string]$branchName,

        [Parameter(Mandatory = $true)]
        [string]$shouldStartWith
    )
    return ($branchName.StartsWith("${shouldStartWith}/", "CurrentCultureIgnoreCase") -or $branchName.StartsWith("${shouldStartWith}-", "CurrentCultureIgnoreCase")  -or $branchName.StartsWith("${shouldStartWith}_", "CurrentCultureIgnoreCase"))            
}

function Get-Branch-Icon{
    param(
        [Parameter(Mandatory = $true)]
        [string]$branchName,

        [Parameter(Mandatory = $true)]
        [array]$branchTypes,

        [Parameter(Mandatory = $true)]
        [hashtable]$glyphs,

        [Parameter(Mandatory = $true)]
        [bool]$setIconColor
    )

    $selectedBranchType = $null
    foreach ($branchType in $branchTypes) {
        if($null -ne $branchType.branchNames){
            foreach ($bn in $branchType.branchNames) {
                if($bn -eq $branchName){
                    $selectedBranchType = $branchType
                    break                    
                }
            }
        }
        if($null -ne $branchType.branchStartsWith){
            foreach ($bs in $branchType.branchStartsWith){
                if(Get-Is-Branch-Type -branchName $branchName -shouldStartWith $bs){
                    $selectedBranchType = $branchType
                    break                
                }
            }
        }
    }

    if($null -eq $selectedBranchType){
        return " "
    }else{
        $icon = $glyphs[$selectedBranchType.icon]
        if($setIconColor){
            $color = (ConvertFrom-RGBColor -RGB ($selectedBranchType.color))
            return -join($color, $icon) 
        }else{
            return $icon
        }
    }
}

function Get-Matching-Branches{
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$branchName,
    
        [Parameter(Mandatory = $true)]
        [System.Object[]]$branches
    )

    $matchedBranches = @()

    foreach ($branch in $branches) {
        $bn = $branch.name

        if($branchName -eq "" -or $branchName -eq $null -or ($bn.Contains($branchName, "CurrentCultureIgnoreCase")) -and -not $branch.isCurrent){
            $matchedBranches += $branch
        }
    }

    return $matchedBranches
}

function New-InteractiveMenu-BranchItem{
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$matchedBranches,

        [Parameter(Mandatory = $true)]
        $branchTypes       
    )

    $menu = @()

    foreach ($branch in $matchedBranches) {
        $isLocal = $branch.isLocal
        $isRemote = $branch.isRemote
        $bn = $branch.name

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
    return $menu    
}