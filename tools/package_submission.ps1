param(
    [string]$VideoUrl = '',
    [switch]$AllowMissingVideo
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..')
)
$submissionId = '24125023_24125078_24125093_24125107'
$submissionRoot = Join-Path $repositoryRoot 'submission'
$packageRoot = Join-Path $submissionRoot $submissionId
$zipPath = Join-Path $submissionRoot "$submissionId.zip"
$videoFile = Join-Path $repositoryRoot 'video\demo-link.txt'

if ([string]::IsNullOrWhiteSpace($VideoUrl)) {
    if (-not (Test-Path -LiteralPath $videoFile)) {
        throw 'video/demo-link.txt is missing.'
    }
    $VideoUrl = (Get-Content -LiteralPath $videoFile -TotalCount 1).Trim()
}

$missingVideo = [string]::IsNullOrWhiteSpace($VideoUrl) -or
    $VideoUrl -match 'PLACEHOLDER|example\.(com|invalid)|TBD'
if ($missingVideo) {
    if (-not $AllowMissingVideo) {
        throw 'Add the public HTTPS video URL first, or use -AllowMissingVideo to stage an incomplete package.'
    }
    $VideoUrl = 'DEMO_VIDEO_LINK_PLACEHOLDER'
    Write-Warning 'Video link is pending. This package is not ready for submission.'
} elseif ($VideoUrl -notmatch '^https://') {
    throw 'The demo video must use a public HTTPS URL.'
}

$apkSource = Join-Path $repositoryRoot 'apk\app-release.apk'
$reportSource = Join-Path $repositoryRoot 'report\report.pdf'
foreach ($requiredFile in @($apkSource, $reportSource)) {
    if (-not (Test-Path -LiteralPath $requiredFile)) {
        throw "Required deliverable is missing: $requiredFile"
    }
}

if (Test-Path -LiteralPath $packageRoot) {
    $resolvedPackageRoot = [System.IO.Path]::GetFullPath($packageRoot)
    if (-not $resolvedPackageRoot.StartsWith($submissionRoot)) {
        throw 'Refusing to clean a staging path outside submission/.'
    }
    Remove-Item -LiteralPath $resolvedPackageRoot -Recurse -Force
}
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

$sourceRoot = Join-Path $packageRoot 'src'
New-Item -ItemType Directory -Path $sourceRoot -Force | Out-Null

$sourceFiles = & git -C $repositoryRoot ls-files --cached --others `
    --exclude-standard
if ($LASTEXITCODE -ne 0) {
    throw 'Could not enumerate the repository source files.'
}

$excludedPrefixes = @(
    '.idea/', '.dart_tool/', '.gradle-tmp/', 'build/', 'coverage/',
    'node_modules/', 'submission/', 'tmp/', 'apk/', 'report/', 'video/',
    'output/', '.idea/', '.gradle/', 'gradle/'
)
foreach ($relativePath in $sourceFiles) {
    $normalizedPath = $relativePath.Replace('\', '/')
    if ($excludedPrefixes | Where-Object {
        $normalizedPath.StartsWith($_, [System.StringComparison]::OrdinalIgnoreCase)
    }) {
        continue
    }
    if ($normalizedPath -match '(^|/)(build|node_modules|\.idea|\.gradle|\.dart_tool)/') { continue }
    if ($normalizedPath -match '(^|/)key\.properties$|(^|/)local\.properties$|\.jks$|\.keystore$|(^|/)\.env') {
        continue
    }

    $sourceFile = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
        continue
    }
    $destinationFile = Join-Path $sourceRoot $relativePath
    New-Item -ItemType Directory -Path (Split-Path $destinationFile) `
        -Force | Out-Null
    Copy-Item -LiteralPath $sourceFile -Destination $destinationFile
}

# Flutter's baseline ignores its wrapper launchers even though they are useful
# in a submitted source snapshot. Include only these known build inputs.
foreach ($relativePath in @(
    'android\gradlew',
    'android\gradlew.bat',
    'android\gradle\wrapper\gradle-wrapper.jar'
)) {
    $sourceFile = Join-Path $repositoryRoot $relativePath
    if (Test-Path -LiteralPath $sourceFile -PathType Leaf) {
        $destinationFile = Join-Path $sourceRoot $relativePath
        New-Item -ItemType Directory -Path (Split-Path $destinationFile) `
            -Force | Out-Null
        Copy-Item -LiteralPath $sourceFile -Destination $destinationFile
    }
}

# The requirements allow a Git log export instead of copying .git.
$history = & git -C $repositoryRoot log --all --date=iso-strict --format=fuller --stat
if ($LASTEXITCODE -ne 0) { throw 'Could not export Git history.' }
[System.IO.File]::WriteAllLines(
    (Join-Path $sourceRoot 'git-log.txt'),
    $history,
    [System.Text.UTF8Encoding]::new($false)
)

$packagedReadme = Join-Path $packageRoot 'README.md'
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'submission-readme.md') `
    -Destination $packagedReadme
$readmeText = Get-Content -LiteralPath $packagedReadme -Raw
if (-not $readmeText.Contains('DEMO_VIDEO_LINK_PLACEHOLDER')) {
    throw 'README.md does not contain the expected video-link placeholder.'
}
$readmeText = $readmeText.Replace('DEMO_VIDEO_LINK_PLACEHOLDER', $VideoUrl)
if (-not $missingVideo) {
    $readmeText = $readmeText.Replace('Replace the placeholder with a Google Drive or YouTube link viewable by anyone with the link. The video must be 5-10 minutes, with all four members speaking. The package is not ready to submit until this is filled in.', 'The demo must be viewable by anyone with the link.')
    $readmeText = $readmeText.Replace('demo URL, pending completion.', 'demo URL.')
}
[System.IO.File]::WriteAllText(
    $packagedReadme,
    $readmeText,
    [System.Text.UTF8Encoding]::new($false)
)

New-Item -ItemType Directory -Path (Join-Path $packageRoot 'apk') -Force |
    Out-Null
New-Item -ItemType Directory -Path (Join-Path $packageRoot 'report') -Force |
    Out-Null
New-Item -ItemType Directory -Path (Join-Path $packageRoot 'video') -Force |
    Out-Null
Copy-Item -LiteralPath $apkSource `
    -Destination (Join-Path $packageRoot 'apk\app-release.apk')
Copy-Item -LiteralPath $reportSource `
    -Destination (Join-Path $packageRoot 'report\report.pdf')
[System.IO.File]::WriteAllText(
    (Join-Path $packageRoot 'video\demo-link.txt'),
    "$VideoUrl`r`n",
    [System.Text.UTF8Encoding]::new($false)
)

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory(
    $packageRoot,
    $zipPath,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $true
)

Write-Host "Created $zipPath"
