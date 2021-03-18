
function Get-Available-InteractiveMenu-Size{
    param(
        [Parameter(Mandatory = $true)]
        [array]$itemsList,

        [Parameter(Mandatory = $true)]
        [short]$numberOfHeaderLines    
    )
    $consoleHeight = $Host.UI.RawUI.WindowSize.Height
    $availMenuSize = $consoleHeight - $numberOfHeaderLines - 2

    if($availMenuSize -gt $itemsList.Length){
        $availMenuSize = $itemsList.Length
    }
    return $availMenuSize
}

function Show-InteractiveMenu{
    param(
        [Parameter(Mandatory = $true)]
        [array]$itemsList,

        [Parameter(Mandatory = $true)]
        [short]$position,

        [Parameter(Mandatory = $true)]
        [short]$numberOfHeaderLines,
        
        [Parameter(Mandatory = $true)]
        [short]$positionsToMove,

        [Parameter(Mandatory = $true)]
        [string]$activeColor
    )

    $selectedItemIcon = [char]::ConvertFromUtf32(0xf061)

    $itemIndex = 0

    foreach ($item in $itemsList) {
        $color = $colors.white
        $prev = "   "
        if($itemIndex -eq ($position - $positionsToMove)){
            $prev = " ${selectedItemIcon} "
            $color = $activeColor
        }

        Write-Host "${color}${prev}${item}"

        $itemIndex++
    }

}

function New-InteractiveMenu{
    param(
        [Parameter(Mandatory = $true)]
        [array]$itemsList,

        [Parameter(Mandatory = $false)]
        [short]$numberOfHeaderLines,

        [string]$activeColor
    )

    if("" -eq $activeColor -or $null -eq $activeColor){
        $activeColor = $colors.green
    }

    $position = 0
    $virtualkeycode = $null
    [console]::CursorVisible = $False
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width

    $lengthAdjustedItemsList = @()
    
    $maxItemWidth = $consoleWidth - 3

    foreach ($item in $itemsList) {
        if($item.length -gt $maxItemWidth){
            $lengthAdjustedItemsList += $item.Substring(0, ($maxItemWidth - 3)) + "..."
        }else{
            $lengthAdjustedItemsList += ($item.PadRight($maxItemWidth, " "))
        }
    }

    $itemsList = $lengthAdjustedItemsList

    $availMenuSize = Get-Available-InteractiveMenu-Size -itemsList $itemsList -numberOfHeaderLines $numberOfHeaderLines

    $trimmedItemsList = $itemsList[0..($availMenuSize - 1)]

    Show-InteractiveMenu -itemsList $trimmedItemsList -position $position -numberOfHeaderLines $numberOfHeaderLines -positionsToMove 0 -activeColor $activeColor

    while(27 -ne $virtualkeycode -and 13 -ne $virtualkeycode){ # Until esc or enter is pressed
        $pressedKeyData = $host.ui.rawui.readkey("IncludeKeyDown,NoEcho")
        $virtualkeycode = $pressedKeyData.virtualkeycode

        switch($virtualkeycode){
            38 { # Up
                $position--
            }
            40 { # Down
                $position++
            }
        }

        if (0 -gt $position) {
            $position = 0
        }
        if ($position -ge $itemsList.length) {
            $position = $itemsList.length -1
        }

        if(27 -eq $virtualkeycode){ # esc pressed
            [console]::CursorVisible = $True
            return $null
        }

        if(13 -eq $virtualkeycode){ # enter pressed
            [console]::CursorVisible = $True
            return $position
        }

        if($position -gt ($availMenuSize - 2)){
            $positionsToMove = $position - ($availMenuSize - 1)
            $trimmedItemsList = $itemsList[$positionsToMove..(($availMenuSize - 1) + $positionsToMove)]
        }
        $drawStartPosition = [System.Console]::CursorTop - $availMenuSize # $itemsList.Length
        [System.Console]::SetCursorPosition(0, $drawStartPosition)
        Show-InteractiveMenu -itemsList $trimmedItemsList -position $position -numberOfHeaderLines $numberOfHeaderLines -positionsToMove $positionsToMove -activeColor $activeColor
    }
}