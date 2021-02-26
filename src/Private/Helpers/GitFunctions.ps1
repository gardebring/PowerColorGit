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

    foreach($branch in $availableBranches){
        $isCurrent = $branch.isCurrent -eq "*"
        $isRemote = $branch.branch -like("*remotes/*")
        $isLocal = $branch.branch -notlike("*remotes/*")
        $addCurrent = $True
        $index = 0;

        foreach($addedBranch in $branches["branchName"]){
            $c = $branch.branch -like("*$addedBranch*")
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