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

    $branchTypes = $commandConfig.branchTypes

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

        $output = -join($output, (Get-Branch-Icon -branchName $bn -branchTypes $branchTypes -glyphs $glyphs -setIconColor $true), $color, " ")

        $output = -join($output, $bn, $nl)
    $index++
    }
  
    Set-Location $directory
    return $output
}

