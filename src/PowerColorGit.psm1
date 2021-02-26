#Requires -Modules Terminal-Icons
. $PSScriptRoot/Init/Import-Dependencies.ps1

function PowerColorGit{
<#
 .Synopsis
  Synopsis.

 .Description
  Description

 .Example
   # Show help
   PowerColorGit -h
#>

  $arguments = $args

  # No command given. Just run default git (help) command and exit.
  if($arguments.Length -eq 0){
    . git
    return
  }

  $command = $arguments[0].Trim().ToLower()
  $params = @()

  if($arguments.Length -gt 1){
    # We got args. Let's collect them!
    $params = $arguments | Select-Object -Skip 1
    $params = $params.ForEach({ $_ -replace "--", "-" })
  }

  # get the current directory Test conflict 7
  $directory = (Get-Location).Path

  $isGitDirectory = Get-IsGitDirectory -directory $directory

  if(-not $isGitDirectory){
    . git $arguments
    return
  }

  # read configuration:
  $config = Get-Content -Path "$PSScriptRoot\config.json" -Raw | ConvertFrom-Json


  switch($command){
    "status"{
      $r = (Get-Command-Status -directory $directory -params $params)
      if($null -eq $r){
        . git $arguments
      }else{
        Write-Host $r
      }
      break;
    }
    "branch"{
      $r = (Get-Command-Branch -directory $directory -params $params -config $config)
      if($null -eq $r){
        . git $arguments
      }else{
        Write-Host $r
      }
      break;
    }
    "checkout"{
      $r = (Get-Command-Checkout -directory $directory -params $params -config $config)
      if($null -eq $r){
        . git $arguments
      }else{
        #Write-Host $r
      }
      break;
    }    
    default{
      . git $arguments
      break;
    }
  }
}

Export-ModuleMember -Function PowerColorGit
