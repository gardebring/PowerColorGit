function Get-Command-Status{
    param(
        [Parameter(Mandatory = $true)]
        [string]$directory,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [array]$params
    )

    # Start internal functions
    function Get-ChangedFileOutput{
      param(
        [Parameter(Mandatory = $true)]
        [string]$icon, 
    
        [Parameter(Mandatory = $true)]
        [string]$fileName,
    
        [Parameter(Mandatory = $true)]
        [string]$fileColor,
    
        [Parameter(Mandatory = $true)]
        [string]$gitColor,

        [Parameter(Mandatory = $false)]
        [string]$gitColor2,        
    
        [Parameter(Mandatory = $true)]
        [string]$gitIcon,

        [Parameter(Mandatory = $false)]
        [string]$gitIcon2
      )  

      $space = "  " 
      if("" -ne $gitIcon2){
        $space = " " 
      }

      return "${space}${gitColor}${gitIcon}${gitColor2}${gitIcon2} ${fileColor}${icon} ${fileName}"
    }
    
    function Get-Upstream-Branch-Status{
      param(
        [Parameter(Mandatory = $true)]
        $branchInfo, 
    
        [Parameter(Mandatory = $true)]
        $colors 
      )
    
      $white = $colors.white
      $purple = $colors.purple
      $green = $colors.green
      $red = $colors.red
      $ahead = $branchInfo.ahead
      $behind = $branchInfo.behind
      $upstreamBranch = $branchInfo.upstreamBranch
  
      if(($ahead -gt 0) -and ($behind -gt 0)){
        return "${white}Your branch and '${green}${upstreamBranch}${white}' have ${red}diverged${white},`r`nand have ${green}${ahead}${white} and ${green}${behind}${white} different commits each, respectively."
      }
      if($ahead -gt 0){
        if($ahead -eq 1){
          return "${white}Your branch is ${purple}ahead${white} of '${green}${upstreamBranch}${white}' by ${green}${ahead}${white} commit."
        }else{
          return "${white}Your branch is ${purple}ahead${white} of '${green}${upstreamBranch}${white}' by ${green}${ahead}${white} commits."
        }
      }
      if($behind -gt 0){
        if($behind -eq 1){
          return "${white}Your branch is ${red}behind${white} '${green}${upstreamBranch}${white}' by ${green}${behind}${white} commit."
        }else{
          return "${white}Your branch is ${red}behind${white} '${green}${upstreamBranch}${white}' by ${green}${behind}${white} commits."
        }
      }
      if(($ahead -eq 0) -and ($behind -eq 0)){
        return "${white}Your branch is ${.green}up to date${white} with '${green}${upstreamBranch}${white}'."
      }
    }
  
    function Get-Status-Icon-And-Color{
      param(
        [Parameter(Mandatory = $true)]
        $statusObject
      )
      
      if($statusObject.added){
        $statusObject.icon = $glyphs["nf-fa-plus"]
        $statusObject.color = $colors.green
      }elseif($statusObject.modified){
        $statusObject.icon = $glyphs["nf-fa-pencil"]
        $statusObject.color = $colors.green
      }elseif($statusObject.deleted){
        $statusObject.icon = $glyphs["nf-fa-remove"]
        $statusObject.color = $colors.red
      }elseif($statusObject.renamed){
        $statusObject.icon = $glyphs["nf-fa-arrow_right"]
        $statusObject.color = $colors.purple
      }
    }
  
    function Get-File-ChangeStatus{
      param(
        [Parameter(Mandatory = $true)]
        [string]$status,
  
        [Parameter(Mandatory = $true)]
        $statusObject
      )
  
      switch($status){
        "M"{ $statusObject.modified = $true }
        "A"{ $statusObject.added = $true }
        "D"{ $statusObject.deleted = $true }
        "R"{ $statusObject.renamed = $true }
      }
    }
    # End  internal functions

    foreach ($param in $params) {
      if($null -ne $param){
          $p = "$param".Trim()
          switch ($p) {
            {(($p -eq "-long"))} {
              # just ignore, this is what we already do..
              break
            }            
            default{
                return $null;
            }
          }
      }
  }
    
    $gitStatus = git status --porcelain=v2 --branch
  
    $branchInfo = @{
      name = $null
      upstreamBranch = $null
      ahead = 0
      behind = 0
    }
  
    $gitStatusItems = @()
  
    foreach($gitStatusItem in $gitStatus){

      $gs = $gitStatusItem.Trim().Split(" ")      

      $gitStatuses= @{
        added = $false
        modified = $false
        deleted = $false
        renamed = $false
        icon = $null
        color = $null
      }

      $item = @{
        staged = $gitStatuses.Clone()
        unStaged = $gitStatuses.Clone()
        changeToBeCommitted = $false
        changeNotStagedForCommit = $false
        untracked = $false
        unmergedPath = $false
        unmerged = @{
          indexStatus = $gitStatuses.Clone() #local
          workingTreeStatus = $gitStatuses.Clone() #remote
        }
        fileName = $null
        status = $gs[1]
        color = $null
        icon = $null
      }
  
      switch($gs[0]){
        "#" # branch status info
        {
          if($item.status -eq "branch.head"){
            $branchInfo.name = $gs[2]
          }
  
          if($item.status -eq "branch.upstream"){
            $branchInfo.upstreamBranch = $gs[2]
          }
  
          if($item.status -eq "branch.ab"){
            #ahead/behind
            $branchInfo.ahead = $gs[2].substring(1)
            $branchInfo.behind = $gs[3].substring(1)
          }
        }
        "1" # changed item
        {
          if($item.status[0] -ne "."){
            $item.changeToBeCommitted = $true
          }
  
          if($item.status[1] -ne "."){
            $item.changeNotStagedForCommit = $true
          }

          Get-File-ChangeStatus -status $item.status[0] -statusObject $item.staged
          Get-File-ChangeStatus -status $item.status[1] -statusObject $item.unStaged
  
          $item.fileName = $gs[8]
        }
        "2" # renamed or copied
        {
          if($item.status[0] -ne "."){
            $item.changeToBeCommitted = $true
          }
  
          if($item.status[1] -ne "."){
            $item.changeNotStagedForCommit = $true
          }

          Get-File-ChangeStatus -status $item.status[0] -statusObject $item.staged
          Get-File-ChangeStatus -status $item.status[1] -statusObject $item.unStaged

          $fileNameArr = $gs[9].Trim().Split("`t")
          $fromFileName = $fileNameArr[1]
          $toFileName = $fileNameArr[0]
          $fromColor = Get-Color -fileName $fromFileName -colorTheme $colorTheme
          $toColor = Get-Color -fileName $toFileName -colorTheme $colorTheme
  
          $item.fileName = -join($fromColor, $fromFileName, " ", $colors.white, $glyphs["nf-fa-long_arrow_right"], " ", $toColor,  $toFileName)
        }
        "u" #unmerged
        {
          #local       remote
          #D           D    unmerged, both deleted
          #A           U    unmerged, added by us
          #U           D    unmerged, deleted by them
          #U           A    unmerged, added by them
          #D           U    unmerged, deleted by us
          #A           A    unmerged, both added
          #U           U    unmerged, both modified

          #unMerged = @{
            #indexStatus = $gitStatuses.Clone() #local
            #workingTreeStatus = $gitStatuses.Clone() #remote
          #}          

          $conflictType = $gs[1]
          #$subModuleState = $gs[2]
          $item.fileName = $gs[10]
          $item.unmergedPath = $true


          switch($conflictType[0]){
            "D"{ $item.unMerged.indexStatus.deleted = $true }
            "A"{ $item.unMerged.indexStatus.added = $true }
            "U"{ $item.unMerged.indexStatus.modified = $true }
          }

          switch($conflictType[1]){
            "D"{ $item.unMerged.workingTreeStatus.deleted = $true }
            "A"{ $item.unMerged.workingTreeStatus.added = $true }
            "U"{ $item.unMerged.workingTreeStatus.modified = $true }
          }

          #Write-Host $conflictType
          #Write-Host $subModuleState
          #Write-Host $item.fileName
        }
        "?" # untracked
        {
          $item.untracked = $true
          $item.fileName = $gs[1]
        }
        "!" # ignored
        {
        }
      }
  
      if($null -ne $item.fileName){
        $item.icon = (Get-Icon -fileName $item.fileName -iconTheme $iconTheme -glyphs $glyphs)
        $item.color = (Get-Color -fileName $item.fileName -colorTheme $colorTheme)
        
        $item.staged.icon = $glyphs["nf-fa-question"]
        $item.unStaged.icon = $glyphs["nf-fa-question"]
        $item.staged.color = $colors.green
        $item.unStaged.color = (ConvertFrom-RGBColor -RGB ("FFFF00"))
  
        Get-Status-Icon-And-Color -statusObject $item.staged
        Get-Status-Icon-And-Color -statusObject $item.unStaged
        Get-Status-Icon-And-Color -statusObject $item.unMerged.indexStatus
        Get-Status-Icon-And-Color -statusObject $item.unMerged.workingTreeStatus

        $gitStatusItems += $item 
      }
    }
  
    $stagedChanges = $gitStatusItems | Where-Object {$true -eq $_.changeToBeCommitted}
    $notStagedChanges = $gitStatusItems | Where-Object {$true -eq $_.changeNotStagedForCommit}
    $unTrackedChanges = $gitStatusItems | Where-Object {$true -eq $_.untracked}
    $unmergedChanges = $gitStatusItems | Where-Object {$true -eq $_.unmergedPath}
  
    $nl = "`r`n"
    $output = -join($colors.white, "On branch '", $colors.green, $branchInfo.name, $colors.white, "'", $nl)
  
    if($null -ne $branchInfo.upstreamBranch){
        $upstreamBranchStatus = (Get-Upstream-Branch-Status -branchInfo $branchInfo -colors $colors)
        $output = -join($output, $upstreamBranchStatus, $nl)
    }

    $output = -join($output, $nl)

    if($unmergedChanges.Length -gt 0){
      $output = -join($output, $colors.white, "Unmerged paths:", $nl)
      foreach($gitStatusItem in $unmergedChanges){
        $output = -join($output, (Get-ChangedFileOutput -icon $gitStatusItem.icon -fileName $gitStatusItem.fileName -fileColor $gitStatusItem.color -gitColor $gitStatusItem.unMerged.indexStatus.color -gitIcon $gitStatusItem.unMerged.indexStatus.icon -gitColor2 $gitStatusItem.unMerged.workingTreeStatus.color -gitIcon2 $gitStatusItem.unMerged.workingTreeStatus.icon), $nl)
      }
    }
  
    if($stagedChanges.Length -gt 0){
      $output = -join($output, $colors.white, "Changes to be committed:", $nl)
      foreach($gitStatusItem in $stagedChanges){
        $output = -join($output, (Get-ChangedFileOutput -icon $gitStatusItem.icon -fileName $gitStatusItem.fileName -fileColor $gitStatusItem.color -gitColor $gitStatusItem.staged.color -gitIcon $gitStatusItem.staged.icon), $nl)
      }
    }
  
    if($notStagedChanges.Length -gt 0){
      $output = -join($output, $colors.white, "Changes not staged for commit:", $nl)
      foreach($gitStatusItem in $notStagedChanges){
        $output = -join($output, (Get-ChangedFileOutput -icon $gitStatusItem.icon -fileName $gitStatusItem.fileName -fileColor $gitStatusItem.color -gitColor $gitStatusItem.unstaged.color -gitIcon $gitStatusItem.unstaged.icon), $nl)
      }
    }
  
    if($unTrackedChanges.Length -gt 0){
      $output = -join($output, $colors.white, "Untracked files:", $nl)
      foreach($gitStatusItem in $unTrackedChanges){
        $output = -join($output, (Get-ChangedFileOutput -icon $gitStatusItem.icon -fileName $gitStatusItem.fileName -fileColor $gitStatusItem.color -gitColor $colors.unTracked -gitIcon $glyphs["nf-fa-question"]), $nl)
      }
    }
    
    return $output
  }