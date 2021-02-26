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
    function Get-Is-Branch-Type{
        param(
            [Parameter(Mandatory = $true)]
            [string]$branchName,
    
            [Parameter(Mandatory = $true)]
            [string]$shouldStartWith
        )
        return $branchName.StartsWith("${shouldStartWith}/", "CurrentCultureIgnoreCase") 
            -or $branchName.StartsWith("${shouldStartWith}-", "CurrentCultureIgnoreCase") 
            -or $branchName.StartsWith("${shouldStartWith}_", "CurrentCultureIgnoreCase")
    }
    
    function Get-Branch-Icon{
        param(
            [Parameter(Mandatory = $true)]
            [string]$branchName,
    
            [Parameter(Mandatory = $true)]
            [array]$branchTypes
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
            if($null -ne $branchType.branchStartsWitch){
                foreach ($bs in $branchType.branchStartsWitch){
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
            return -join($selectedBranchType.color, $selectedBranchType.icon) 
        }
    }

    function Get-Options{
        param(
            [Parameter(Mandatory = $true)]
            [AllowEmptyCollection()]
            [array]$params
        )

        $options = @{
            showAll = $false
            remote = $false
        }

        foreach ($param in $params) {
            if($null -ne $param){
                $p = "$param".Trim()
                switch ($p) {
                    {(($p -eq "-a") -or ($p -eq "-all"))} {
                        $options.showAll = $true
                        break
                    }
                    {(($p -eq "-r") -or ($p -eq "-remotes"))} {
                        $options.remote = $true
                        break
                    }
                    default{
                        return $null;
                    }
                }
            }
        }        

        return $options
    }
    # End internal functions

    $options = (Get-Options -params $params)

    if($null -eq $options){
        return $null
    }

    $branchTypes = @(
        @{
            branchNames = @("main", "master")
            branchStartsWitch = $null
            color = $colors.green
            icon = $symbols.crown
        },
        @{
            branchNames = @("stable", "release", "production")
            branchStartsWitch = $null
            color = $colors.green
            icon = $symbols.checkBold
        },
        @{
            branchNames = $null
            branchStartsWitch = @("feature", "topic")
            color = $colors.yellow
            icon = $symbols.star
        },
        @{
            branchNames = $null
            branchStartsWitch = @("bug")
            color = $colors.red
            icon = $symbols.bug
        }
        ,
        @{
            branchNames = $null
            branchStartsWitch = @("hotfix")
            color = $colors.orange
            icon = $symbols.hotfix
        }
    )

      $branches = (Get-Git-Branches-Complex -includehead $commandConfig.showHead -showAll $options.showAll -remote $options.remote)
      
      $output = ""
      $nl = "`r`n"

      $index = 0
          foreach($bn in $branches["branchName"]){
            $isCurrent = $branches["isCurrent"][$index]
            $isLocal = $branches["isLocal"][$index]
            $isRemote = $branches["isRemote"][$index]

            $color = $colors.white

            if($isCurrent){
                $color = $colors.green
            }elseif($isLocal){
                $color = $colors.white
            }elseif($isRemote){
                $color = $colors.brightRed
            }
            
            $output = -join($output, $color)

            if($isCurrent){
                $output = -join($output, $symbols.check, " ")
            }else{
                $output = -join($output, "  ")
            }

            if($isLocal){
                $output = -join($output, $symbols.house, " ")
            }else{
                $output = -join($output, "  ")
            }
            
            if($isRemote){
                $output = -join($output, $symbols.globe, " ")
            }else{
                $output = -join($output, "  ")
            }

            $output = -join($output, (Get-Branch-Icon -branchName $bn -branchTypes $branchTypes), $color, " ")

            $output = -join($output, $bn, $nl)
        $index++
      }
  
    Set-Location $directory
    return $output
}