[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$OutPath
)

$emptyFilePath = Join-Path -Path $OutPath -ChildPath "emptyFile"

if (Test-Path -Path $emptyFilePath) {
    Write-Warning "Removing emptyFile from the 'compiled' branch."
    git rm -f $emptyFilePath
}

$scriptRoot = $PSScriptRoot

$filterListBuildScriptPath = Join-Path -Path $scriptRoot -ChildPath "Invoke-FilterListBuild.ps1"

. $filterListBuildScriptPath -RootPath "/tmp/smalls-filter-lists" -OutPath $OutPath -Verbose

$readmeOutPath = Join-Path -Path $OutPath -ChildPath "README.md"
$licenseOutPath = Join-Path -Path $OutPath -ChildPath "LICENSE"

Copy-Item -Path "/tmp/smalls-filter-lists/README.md" -Destination $readmeOutPath -Force
Copy-Item -Path "/tmp/smalls-filter-lists/LICENSE" -Destination $licenseOutPath -Force

git config user.name "github-actions"
git config user.email "<>"
git add *
git commit -m "Filter lists compiled from 'main' branch"
git push origin compiled
