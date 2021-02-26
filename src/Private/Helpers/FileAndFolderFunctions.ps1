function Get-IsDirectory{
    Param(
        [Parameter(Mandatory = $true)]
        $fileSystemInfo
    )
    return ($fileSystemInfo.GetType()) -eq [System.IO.DirectoryInfo]
}

function Get-FileExtension {
    Param(
        [Parameter(Mandatory = $true)]
        [string]$fileName
    )
    return [System.IO.Path]::GetExtension($fileName)
}

function Get-IsPotentialDirectoryPath{
    Param(
        [Parameter(Mandatory = $true)]
        [string]$path
    )
    return $path.EndsWith("/")
}