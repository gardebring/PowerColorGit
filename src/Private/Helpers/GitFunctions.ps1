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

    $branches = @{
        isCurrent = @()
        branchName = @()
        isRemote = @()
        isLocal = @()
    }
    
    $remotesLikePattern = "*remotes/*"

    foreach($branch in $availableBranches){
        $isCurrent = $branch.isCurrent -eq "*"
        $isRemote = $branch.branch -like($remotesLikePattern)
        $isLocal = $branch.branch -notlike($remotesLikePattern)
        $addCurrent = $True
        $index = 0;

        foreach($addedBranch in $branches["branchName"]){
            $c = $branch.branch -like("*$addedBranch*") -and $branch.branch -like($remotesLikePattern)
            if($c){

                $branches["isRemote"][$index] = $isRemote
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
            $branches["isCurrent"] += $isCurrent
            $branches["isRemote"] += $isRemote
            $branches["isLocal"] += $isLocal
            $branches["branchName"] += $branchName
        }
      }
      
      return $branches
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