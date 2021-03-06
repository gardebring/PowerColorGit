# PowerColorGit

A Powershell module that improves on the git command line experience with colorized output with icons as well as an easier branch selection experience.

## Overview #

*PowerColorGit* is a Powershell module that improves on the git command line experience with simplified and colorized output and simplified branch selection.
For the module to work, you must first install [Terminal-Icons](https://github.com/devblackops/Terminal-Icons/) and setup the [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts/)

The module provides enhancements to the _git status_ _git branch_ and _git checkout_ commands.

For example, this is how the standard output of git status can look like:

![git status standard output](./media/screens/git_status.png)

With PowerColorGit you instead get this output:

![powercolorgit status output](./media/screens/powercolorgit_status.png)

PowerColorGit will also fallback to default behaviour when an option or command is not specifically implemented in PowerColorGit, so you can use commands like _PowerColorGit clone_, _PowerColorGit push_ or _powercolorgit status --short_ even though nothing is implemented in PowerColorGit for these.

## Installation
To install the module from the [PowerShell Gallery](https://www.powershellgallery.com/):
```powershell
Install-Module -Name PowerColorGit -Repository PSGallery
```

## Example usage
```powershell
Import-Module PowerColorGit
PowerColorGit status
PowerColorGit branch
PowerColorGit branch -a
PowerColorGit checkout partialbranchname
```

### List the current working tree status
```powershell
PowerColorGit status
```
![powercolorgit status output](./media/screens/powercolorgit_status.png)

### List all remote-tracking and local branches.
In this example, the currently selected branch is _feature/add_support_for_branch_picker_ as indicated with the green color and checkmark.\
Please note that the HEAD branch will by default not be displayed in PowerColorGit. You can change this in the [configuration](./src/config.json#L4).\
In this example, the only remotely available branch is _main_, all others are local only, as indicated with the icons.
```powershell
PowerColorGit branch -a
```
![powercolorgit branch -a output](./media/screens/powercolorgit_branch_a.png)

### Checkout a branch.
With PowerColorGit you can checkout a branch by providing the full or partial name of a branch.\
If a single match is found based on the name or partial name you provided, you will be switched to that branch.\
If multiple branches were found you will be shown a menu to select which branch you want to switch to.\
You can also completely omit giving a branch name. This will show a menu of all branches except the one you are currently on.\
The _HEAD_ branch will by default not be displayed in PowerColorGit. You can change this in the [configuration](./src/config.json#L53).\
By default, if there is a remote tracking branch, PowerColorGit checkout will do a _git pull_ after checking out a branch. You can change this setting in the [configuration](./src/config.json#L54).\
In the example below three branches matching the partial branch name _feature_ was found, all of them are local only branches as indicated with the icons:
```powershell
PowerColorGit checkout feature
```
![powercolorgit branch -a output](./media/screens/powercolorgit_checkout_selection.png)


## Configuration
In the file [config.json](./src/config.json) you will find some configuration options for PowerColorGit.

## Alias to pcg
Warning. Do not alias to **git** since PowerColorGit uses the git command internally and this would cause the module to call itself.
```powershell
Set-Alias -Name pcg -Value PowerColorGit -Option AllScope
```
