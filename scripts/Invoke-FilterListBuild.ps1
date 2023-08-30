[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$RootPath,
    [Parameter(Position = 1, Mandatory)]
    [string]$OutPath
)

$currentDateTimeString = [System.DateTimeOffset]::UtcNow.UtcDateTime.ToString("ddd, dd MMM yyyy HH:mm:ss zzz")

$rootPathResolved = (Resolve-Path -Path $RootPath -ErrorAction "Stop").Path

if ([System.IO.FileAttributes]::Directory -notin (Get-Item -Path $rootPathResolved).Attributes) {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.IO.IOException]::new("'$($rootPathResolved)' is not a directory."),
            "InvalidDirectory",
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $rootPathResolved
        )
    )
}

$outPathResolved = (Resolve-Path -Path $OutPath -ErrorAction "Stop").Path

if ([System.IO.FileAttributes]::Directory -notin (Get-Item -Path $outPathResolved).Attributes) {
    $PSCmdlet.ThrowTerminatingError(
        [System.Management.Automation.ErrorRecord]::new(
            [System.IO.IOException]::new("'$($outPathResolved)' is not a directory."),
            "InvalidDirectory",
            [System.Management.Automation.ErrorCategory]::InvalidArgument,
            $outPathResolved
        )
    )
}

$outFiltersPath = Join-Path -Path $outPathResolved -ChildPath "filters"

if (!(Test-Path -Path $outFiltersPath)) {
    Write-Warning "The output filters directory '$($outFiltersPath)' does not exist. Creating..."
    $null = New-Item -Path $outFiltersPath -ItemType "Directory" -Force
}

$filtersDirPath = Join-Path -Path $rootPathResolved -ChildPath "filters"

$filterItems = Get-ChildItem -Path $filtersDirPath -Recurse | Where-Object { $PSItem.Extension -eq ".txt" }

foreach ($filterItem in $filterItems) {
    Write-Verbose "Processing '$($filterItem.FullName)'..."
    $filterContent = Get-Content -Path $filterItem.FullName -Raw

    $filterItemOutDirPath = $filterItem.Directory.FullName.Replace($filtersDirPath, $outFiltersPath)

    if (!(Test-Path -Path $filterItemOutDirPath)) {
        $null = New-Item -Path $filterItemOutDirPath -ItemType "Directory" -Force
    }

    $filterItemOutPath = Join-Path -Path $filterItemOutDirPath -ChildPath $filterItem.Name

    $filterContent.Replace("{{ LAST_UPDATED_TIMESTAMP }}", $currentDateTimeString) | Set-Content -Path $filterItemOutPath
}
