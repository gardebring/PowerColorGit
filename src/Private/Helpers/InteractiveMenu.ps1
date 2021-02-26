function Show-InteractiveMenu{
    param(
        [Parameter(Mandatory = $true)]
        [array]$itemsList,

        [Parameter(Mandatory = $true)]
        [short]$position
    )

    $selectedItemIcon = [char]::ConvertFromUtf32(0xf061)

    $itemIndex = 0
    foreach ($item in $itemsList) {
        $color = $colors.white
        $prev = "   "
        if($itemIndex -eq $position){
            $prev = " ${selectedItemIcon} "
            $color = $colors.green
        }
        Write-Host "${color}${prev}${item} "

        $itemIndex++
    }

}

function New-InteractiveMenu{
    param(
        [Parameter(Mandatory = $true)]
        [array]$itemsList
    )

    $position = 0
    $virtualkeycode = $null
    [console]::CursorVisible = $False

    Show-InteractiveMenu -itemsList $itemsList -position $position

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

        $drawStartPosition = [System.Console]::CursorTop - $itemsList.Length
        [System.Console]::SetCursorPosition(0, $drawStartPosition)
        Show-InteractiveMenu -itemsList $itemsList -position $position
    }
}