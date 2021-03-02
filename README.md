# PowerColorGit

A Powershell module that improves on the git command line experience with colorized output with icons as well as an easier branch selection experience.

## Overview #

*PowerColorGit* is a Powershell module that improves on the git command line experience with simplified and colorized output and simplified branch selection.
For the module to work, you must first install [Terminal-Icons](https://github.com/devblackops/Terminal-Icons/) and setup the [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/)

## Installation
Work in progress

## Example usage
```powershell
Import-Module PowerColorGit
PowerColorGit status
PowerColorGit branch
PowerColorGit branch -a
PowerColorGit checkout partalbranchname
```

List the current working tree status
```powershell
PowerColorGit status
```
TODO: Add screenshot

List all remote-tracking and local branches
```powershell
PowerColorGit branch -a
```
TODO: Add screenshot

## Alias to pcg
```powershell
Set-Alias -Name pcg -Value PowerColorGit -Option AllScope
```
