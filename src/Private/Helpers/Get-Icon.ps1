function Get-Icon{
    param(
        [Parameter(Mandatory = $true)]
        [string]$fileName, 

        [Parameter(Mandatory = $true)]
        [hashtable]$iconTheme,

        [Parameter(Mandatory = $true)]
        [hashtable]$glyphs
    )

    $iconName = Get-IconName -fileName $fileName -iconTheme $iconTheme

    return $glyphs[$iconName]
}

# Following are internal methods
function Get-IconName{
    param(
        [Parameter(Mandatory = $true)]
        [string]$fileName, 
        
        [Parameter(Mandatory = $true)]
        [hashtable]$iconTheme
    )
    
    $isDirectory = Get-IsPotentialDirectoryPath -path $fileName 

    $fileExt = Get-FileExtension -fileName $fileName

    if($isDirectory){
        $iconName = Get-FolderIconName -name $fileName -iconTheme $iconTheme
    }else{
        $iconName = Get-FileIconName -name $fileName -fileExt $fileExt -iconTheme $iconTheme
    }

    $iconName = Get-PatchedIconName -iconName $iconName

    return $iconName
}


function Get-PatchedIconName{
    param(
        [Parameter(Mandatory = $true)]
        [string]$iconName
    )

    switch($iconName){
        "nf-mdi-view_list"{
            return "nf-fa-th_list"
        }
        "nf-mdi-xml"{
            return "nf-fa-code"
        }
        default{
            return $iconName
        }
    }
}

function Get-FolderIconName{
    param(
        [Parameter(Mandatory = $true)]
        [string]$name,

        [Parameter(Mandatory = $true)]
        [hashtable]$iconTheme
    )

    $iconName = $iconTheme.Types.Directories.WellKnown[$name]

    if($null -eq $iconName){
        $iconName = $iconTheme.Types.Directories[""]
    }

    return $iconName
}

function Get-FileIconName{
    param(
        [Parameter(Mandatory = $true)]
        [string]$name, 
        
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$fileExt, 
        
        [Parameter(Mandatory = $true)]
        [hashtable]$iconTheme
    )

    $iconName = $iconTheme.Types.Files.WellKnown[$name]
    if($null -eq $iconName){
        $iconName = $iconTheme.Types.Files[$fileExt]
    }
    if($null -eq $iconName){
        $iconName = $iconTheme.Types.Files[""]
    }

    return $iconName
}


$symbols = @{
    checkBold = [char]::ConvertFromUtf32(0xf00c)
    check = [char]::ConvertFromUtf32(0x2713)
    house = [char]::ConvertFromUtf32(0xF015)
    globe = [char]::ConvertFromUtf32(0xf484)
    star = [char]::ConvertFromUtf32(0xf006)
    bug = [char]::ConvertFromUtf32(0xf188)
    crown = [char]::ConvertFromUtf32(0xf6a4)
    hotfix = [char]::ConvertFromUtf32(0xf06d)
}