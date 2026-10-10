[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $StageDirectory,
    [Parameter(Mandatory = $true)]
    [string] $QtRoot,
    [string] $TranslationsRoot,
    [string] $VcpkgPrefix,
    [string] $CrtDirectory,
    [string] $OutputDirectory,
    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string] $ReleaseName,
    [string] $SourceArchive,
    [switch] $IncludeSymbols
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$packageRoot = Split-Path -Parent $PSScriptRoot
$stagePath = (Resolve-Path -LiteralPath $StageDirectory).Path
$qtPath = (Resolve-Path -LiteralPath $QtRoot).Path
if (-not $TranslationsRoot)
{
    $TranslationsRoot = $QtRoot
}
$translationsPath = (Resolve-Path -LiteralPath $TranslationsRoot).Path
if (-not (Test-Path -LiteralPath (Join-Path $translationsPath 'translations/qtbase_pl.qm')))
{
    throw 'Supply matching Qt 6.10.3 translations with -TranslationsRoot, including qtbase_pl.qm.'
}
if (-not $VcpkgPrefix)
{
    $VcpkgPrefix = Join-Path $packageRoot 'build/deps/vcpkg/installed/x64-windows-static-md-release'
}
$dependencyPath = (Resolve-Path -LiteralPath $VcpkgPrefix).Path
$nativeManifestPath = Join-Path $stagePath 'libtorrent-build.json'
$nativeManifest = Get-Content -LiteralPath $nativeManifestPath -Raw | ConvertFrom-Json
if ($nativeManifest.linkage -ne 'static')
{
    throw 'The staged libtorrent manifest must describe static linkage.'
}
$modeName = if ($nativeManifest.patch_mode -eq 'ON') { 'patched' } else { 'baseline' }
if (-not $ReleaseName)
{
    $ReleaseName = 'LoriiTorrent-5.2.4-r3-Windows-x64-Portable'
}
if (-not $OutputDirectory)
{
    $OutputDirectory = Join-Path $packageRoot 'build/releases'
}
$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
$releasePath = Join-Path $outputPath $ReleaseName
$zipPath = "$releasePath.zip"
if ((Test-Path -LiteralPath $releasePath) -or (Test-Path -LiteralPath $zipPath))
{
    throw 'The release output already exists. Choose a new ReleaseName; existing artifacts are preserved.'
}

if (-not $CrtDirectory)
{
    $redistRoot = $env:VCToolsRedistDir
    if ($redistRoot)
    {
        $CrtDirectory = Join-Path $redistRoot 'x64/Microsoft.VC143.CRT'
    }
    else
    {
        $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
        $visualStudioPath = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        if ($LASTEXITCODE -ne 0 -or -not $visualStudioPath)
        {
            throw 'Supply the licensed VS 2022 x64 Microsoft.VC143.CRT directory with -CrtDirectory.'
        }
        $redistVersions = Get-ChildItem -LiteralPath (Join-Path $visualStudioPath 'VC/Redist/MSVC') -Directory |
            Where-Object { $_.Name -match '^14\.\d+\.\d+$' } |
            Sort-Object { [version] $_.Name } -Descending
        if (-not $redistVersions)
        {
            throw 'No Visual Studio redistributable directory is installed.'
        }
        $CrtDirectory = Join-Path $redistVersions[0].FullName 'x64/Microsoft.VC143.CRT'
    }
}
$crtPath = (Resolve-Path -LiteralPath $CrtDirectory).Path
if ($crtPath -notmatch '[\\/]VC[\\/]Redist[\\/]MSVC[\\/].*[\\/]x64[\\/]Microsoft\.VC143\.CRT$')
{
    throw 'CRT files must come from the official VS VC/Redist/MSVC x64 Microsoft.VC143.CRT directory.'
}
foreach ($required in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll'))
{
    if (-not (Test-Path -LiteralPath (Join-Path $crtPath $required)))
    {
        throw "Missing x64 redistributable runtime: $required."
    }
}

$licenseRoot = Join-Path $PSScriptRoot 'third-party'
foreach ($required in @('libtorrent-2.0.15-LICENSE', 'libtorrent-2.0.15/COPYING',
    'libtorrent-2.0.15/AUTHORS', 'libtorrent-2.0.15/try_signal-LICENSE',
    'qbittorrent-5.2.4/COPYING', 'qbittorrent-5.2.4/COPYING.GPLv2',
    'qbittorrent-5.2.4/COPYING.GPLv3', 'qbittorrent-5.2.4/AUTHORS',
    'qt-6.10.3/LGPL-3.0-only.txt', 'qt-6.10.3/GPL-3.0-only.txt'))
{
    if (-not (Test-Path -LiteralPath (Join-Path $licenseRoot $required)))
    {
        throw "Missing prepared dependency license: $required."
    }
}
New-Item -ItemType Directory -Path $releasePath -Force | Out-Null
$stageFiles = Get-ChildItem -LiteralPath $stagePath -File -Recurse
foreach ($file in $stageFiles)
{
    # Use Windows' own system ICU/Direct3D libraries; do not redistribute OS copies.
    if ($file.Name -in @('d3dcompiler_47.dll', 'dxcompiler.dll', 'dxil.dll', 'icuuc.dll'))
    {
        continue
    }
    if (-not $IncludeSymbols -and $file.Extension -eq '.pdb')
    {
        continue
    }
    $relativePath = $file.FullName.Substring($stagePath.Length).TrimStart([char[]] '\/')
    $destinationPath = Join-Path $releasePath $relativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $destinationPath) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destinationPath
}
$releaseBin = Join-Path $releasePath 'bin'
Get-ChildItem -LiteralPath $crtPath -Filter '*.dll' -File | Copy-Item -Destination $releaseBin

# These plugins are loaded dynamically and may not appear in PE import tables.
foreach ($plugin in @('platforms/qwindows.dll', 'sqldrivers/qsqlite.dll', 'iconengines/qsvgicon.dll', 'tls/qschannelbackend.dll'))
{
    $pluginDestination = Join-Path $releaseBin "plugins/$plugin"
    if (-not (Test-Path -LiteralPath $pluginDestination))
    {
        $pluginSource = Join-Path $qtPath "plugins/$plugin"
        if (-not (Test-Path -LiteralPath $pluginSource))
        {
            throw "Missing required Qt plugin: $plugin."
        }
        New-Item -ItemType Directory -Path (Split-Path -Parent $pluginDestination) -Force | Out-Null
        Copy-Item -LiteralPath $pluginSource -Destination $pluginDestination
    }
}
foreach ($required in @('qbittorrent.exe', 'Qt6Core.dll', 'Qt6Gui.dll', 'Qt6Widgets.dll', 'Qt6Network.dll', 'Qt6Sql.dll', 'Qt6Svg.dll', 'Qt6Xml.dll', 'qt.conf'))
{
    if (-not (Test-Path -LiteralPath (Join-Path $releaseBin $required)))
    {
        throw "Missing staged application dependency: $required."
    }
}
$releaseTranslations = Join-Path $releaseBin 'translations'
New-Item -ItemType Directory -Path $releaseTranslations -Force | Out-Null
Get-ChildItem -LiteralPath (Join-Path $translationsPath 'translations') -Filter '*.qm' -File |
    Copy-Item -Destination $releaseTranslations

$releaseLicenses = Join-Path $releasePath 'licenses'
New-Item -ItemType Directory -Path $releaseLicenses -Force | Out-Null
Copy-Item -LiteralPath $licenseRoot -Destination (Join-Path $releaseLicenses 'prepared') -Recurse
Copy-Item -LiteralPath (Join-Path $stagePath 'COPYING') -Destination (Join-Path $releaseLicenses 'qBittorrent-COPYING')
Copy-Item -LiteralPath (Join-Path $packageRoot 'LICENSE') -Destination (Join-Path $releaseLicenses 'LoriiTorrent-LICENSE')
Copy-Item -LiteralPath (Join-Path $packageRoot 'NOTICE.md') -Destination (Join-Path $releasePath 'NOTICE.md')
$copyrightFiles = Get-ChildItem -LiteralPath (Join-Path $dependencyPath 'share') -Filter 'copyright' -File -Recurse
foreach ($file in $copyrightFiles)
{
    $portName = Split-Path -Leaf $file.DirectoryName
    Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $releaseLicenses "$portName-copyright.txt")
}
$qtSbomPath = Join-Path $qtPath 'sbom'
if (-not (Test-Path -LiteralPath $qtSbomPath))
{
    throw 'Qt SBOMs are required to retain bundled third-party attribution.'
}
Copy-Item -LiteralPath $qtSbomPath -Destination (Join-Path $releaseLicenses 'qt-sbom') -Recurse
$translationSboms = @(Get-ChildItem -LiteralPath (Join-Path $translationsPath 'sbom') -Filter 'qttranslations-6.10.3*' -File)
if (-not $translationSboms)
{
    throw 'Matching qttranslations SBOM attribution is required.'
}
$translationSboms | Copy-Item -Destination (Join-Path $releaseLicenses 'qt-sbom')
$nativePatchesPath = Join-Path $releasePath 'source-patches'
New-Item -ItemType Directory -Path $nativePatchesPath -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'patches') -Destination (Join-Path $nativePatchesPath 'libtorrent') -Recurse
$supportingPatches = @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'qbittorrent-*.patch' -File)
foreach ($file in $supportingPatches)
{
    Copy-Item -LiteralPath $file.FullName -Destination $nativePatchesPath
}
Copy-Item -LiteralPath (Join-Path $packageRoot 'README.md') -Destination (Join-Path $releasePath 'README.md')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'SOURCE.md') -Destination (Join-Path $releasePath 'SOURCE.md')
if ($SourceArchive)
{
    Copy-Item -LiteralPath (Resolve-Path -LiteralPath $SourceArchive).Path -Destination $releasePath
}
$launcher = "@echo off`r`nstart `"`" `"%~dp0bin\qbittorrent.exe`" `"--profile=%~dp0profile`"`r`n"
[System.IO.File]::WriteAllText((Join-Path $releasePath 'Launch-LoriiTorrent.cmd'), $launcher,
    [System.Text.UTF8Encoding]::new($false))
$publicNative = [ordered] @{}
foreach ($key in @('commit', 'version', 'variant', 'patch_mode', 'patches', 'linkage', 'submodules', 'source_diff_sha256'))
{
    $publicNative[$key] = $nativeManifest.$key
}
$publicNative | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath (Join-Path $releasePath 'libtorrent-build.json') -Encoding utf8
$releaseMetadata = [ordered] @{
    application = 'LoriiTorrent'
    version = '5.2.4-r3'
    sourceCommit = 'a1e4649cb8ae581925acc161dbab5cbc6584c542'
    nativeDependency = $publicNative
    qbittorrentSupportingPatches = @($supportingPatches | ForEach-Object { @{ name = $_.Name; sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() } })
    applicationCodeChanges = 'Application adds invalid webseed range warnings with endpoint and native error details; other qBittorrent patches affect build configuration and test expectations.'
    crtSource = 'Oficjalne pliki VC/Redist/MSVC x64 Microsoft.VC143.CRT z Visual Studio 2022'
    crtVersion = (Get-Item -LiteralPath (Join-Path $crtPath 'vcruntime140.dll')).VersionInfo.FileVersion
    qtSbom = 'licenses/qt-sbom'
    qtTranslations = '6.10.3; bin/translations includes qtbase_pl.qm'
    mode = $modeName
    profile = 'Osobny lokalny folder profile; migracja poprzedniej konfiguracji jest ręczna.'
}
$releaseMetadata | ConvertTo-Json -Depth 16 | Set-Content -LiteralPath (Join-Path $releasePath 'release-manifest.json') -Encoding utf8
$fileHashes = Get-ChildItem -LiteralPath $releasePath -File -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Substring($releasePath.Length).TrimStart([char[]] '\/').Replace('\', '/')
    "$(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256 | Select-Object -ExpandProperty Hash)  $relativePath"
}
$fileHashes | Set-Content -LiteralPath (Join-Path $releasePath 'SHA256SUMS.txt') -Encoding ascii
Compress-Archive -LiteralPath $releasePath -DestinationPath $zipPath -CompressionLevel Optimal
$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
"$zipHash  $([System.IO.Path]::GetFileName($zipPath))" | Set-Content -LiteralPath "$zipPath.sha256" -Encoding ascii
Write-Output "Windows ZIP: $zipPath"
Write-Output "SHA-256: $zipHash"
