[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$OutPath
)

$scriptRoot = $PSScriptRoot

$filterListBuildScriptPath = Join-Path -Path $scriptRoot -ChildPath "Invoke-FilterListBuild.ps1"

. $filterListBuildScriptPath -RootPath "/tmp/smalls-filter-lists" -OutPath $OutPath

Copy-Item -Path "/tmp/smalls-filter-lists/README.md" -Destination $OutPath -Force
Copy-Item -Path "/tmp/smalls-filter-lists/LICENSE" -Destination $OutPath -Force