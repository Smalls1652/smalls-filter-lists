[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [string]$RootPath,
    [Parameter(Position = 1, Mandatory)]
    [string]$OutPath
)

$includeStringRegex = [regex]::new("!#include (?'fileName'.+?)`$")
$includeContentRegex = [regex]::new("(?>!.+?\n)+(?'rules'.+)", [System.Text.RegularExpressions.RegexOptions]::Singleline)

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

    $filterContent = $filterContent.Replace("{{ LAST_UPDATED_TIMESTAMP }}", $currentDateTimeString)

    $filterContent | Set-Content -Path $filterItemOutPath

    if ($includeStringRegex.IsMatch($filterContent)) {
        Write-Verbose "Found include string in '$($filterItem.FullName)'. Creating EasyList variant..."

        $includeMatches = $includeStringRegex.Matches($filterContent)

        foreach ($includeMatch in $includeMatches) {
            $includeFileName = $includeMatch.Groups["fileName"].Value

            $includeFilePath = Join-Path -Path $filterItem.Directory.FullName -ChildPath $includeFileName

            $includeFileContent = Get-Content -Path $includeFilePath -Raw
            
            $includeFileContent = $includeContentRegex.Match($includeFileContent).Groups["rules"].Value

            $filterContent = $filterContent.Replace($includeMatch.Value, $includeFileContent)
        }

        $easyListFilterStringBuilder = [System.Text.StringBuilder]::new()
        $null = $easyListFilterStringBuilder.AppendLine("[Adblock Plus 2.0]")
        $null = $easyListFilterStringBuilder.AppendLine($filterContent)

        $filterItemEasyListOutPath = Join-Path -Path $filterItemOutDirPath -ChildPath "$($filterItem.BaseName).easylist.txt"
        $easyListFilterStringBuilder.ToString() | Set-Content -Path $filterItemEasyListOutPath
    }
}
