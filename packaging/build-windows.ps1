[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string] $QtRoot,
    [string] $SourceDirectory,
    [string] $DependencyPrefix,
    [string] $CMakeToolchainFile,
    [string] $VcpkgTriplet = 'x64-windows',
    [ValidateSet('ON', 'OFF')]
    [string] $LibtorrentPatches = 'ON',
    [string] $LibtorrentSourceDirectory,
    [string[]] $RuntimeDirectories = @(),
    [string[]] $CMakeArguments = @(),
    [int] $BuildJobs = 2,
    [switch] $NoTests
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$packageRoot = Split-Path -Parent $PSScriptRoot
if (-not $SourceDirectory)
{
    $SourceDirectory = Join-Path $packageRoot 'upstream'
}
$sourcePath = (Resolve-Path -LiteralPath $SourceDirectory).Path
$qtPath = (Resolve-Path -LiteralPath $QtRoot).Path
$deployQt = Join-Path $qtPath 'bin/windeployqt.exe'
if (-not (Test-Path -LiteralPath (Join-Path $sourcePath 'CMakeLists.txt')))
{
    throw "Missing qBittorrent sources in $sourcePath."
}
if (-not (Test-Path -LiteralPath $deployQt))
{
    throw "Missing Qt deployment tool: $deployQt."
}
if (-not (Get-Command cl.exe -ErrorAction SilentlyContinue))
{
    throw 'Run this script in Developer PowerShell for VS 2022 with the x64 MSVC environment.'
}
if ($BuildJobs -lt 1)
{
    throw 'BuildJobs must be positive.'
}
foreach ($tool in @('cmake.exe', 'ninja.exe', 'git.exe', 'python.exe'))
{
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue))
    {
        throw "Missing build tool in PATH: $tool."
    }
}

function Invoke-BuildTool
{
    param([string] $Program, [string[]] $ToolArguments)
    & $Program @ToolArguments
    if ($LASTEXITCODE -ne 0)
    {
        throw "$Program failed with exit code $LASTEXITCODE."
    }
}

$prefixes = @($qtPath)
if ($DependencyPrefix)
{
    $prefixes += (Resolve-Path -LiteralPath $DependencyPrefix).Path
}
$testing = if ($NoTests) { 'OFF' } else { 'ON' }
$dependencyArguments = @("-DCMAKE_PREFIX_PATH=$($prefixes -join ';')")
if ($CMakeToolchainFile)
{
    $toolchainPath = (Resolve-Path -LiteralPath $CMakeToolchainFile).Path
    $dependencyArguments += @(
        "-DCMAKE_TOOLCHAIN_FILE=$toolchainPath",
        "-DVCPKG_TARGET_TRIPLET=$VcpkgTriplet",
        '-DVCPKG_APPLOCAL_DEPS=ON'
    )
}
$dependencyArguments += $CMakeArguments
$libtorrentResult = Join-Path $packageRoot "build/libtorrent-result-windows-$LibtorrentPatches.json"
$prepareArguments = @(
    (Join-Path $PSScriptRoot 'prepare-libtorrent.py'),
    '--mode', $LibtorrentPatches,
    '--jobs', "$BuildJobs",
    '--result', $libtorrentResult,
    '--build-root', (Join-Path $packageRoot 'build')
)
if ($LibtorrentSourceDirectory)
{
    $prepareArguments += @('--source', (Resolve-Path -LiteralPath $LibtorrentSourceDirectory).Path)
}
foreach ($argument in $dependencyArguments)
{
    $prepareArguments += "--cmake-arg=$argument"
}
$previousToolPath = $env:PATH
$testRuntimePaths = @((Join-Path $qtPath 'bin')) + $RuntimeDirectories
if ($DependencyPrefix)
{
    $testRuntimePaths += Join-Path $DependencyPrefix 'bin'
}
$env:PATH = ($testRuntimePaths -join ';') + ';' + $previousToolPath
try
{
    Invoke-BuildTool 'python.exe' $prepareArguments
    $libtorrentInfo = Get-Content -LiteralPath $libtorrentResult -Raw | ConvertFrom-Json
    $buildPath = Join-Path $packageRoot "build/qbt-gui-$($libtorrentInfo.variant)"
    $stagePath = Join-Path $packageRoot "build/packages/qbt-gui-$($libtorrentInfo.variant)"
    $stageBin = Join-Path $stagePath 'bin'
    $runtimePaths = @($buildPath) + $RuntimeDirectories
    $configureArguments = @('-S', $sourcePath, '-B', $buildPath, '-G', 'Ninja') + $dependencyArguments + @(
        '-DCMAKE_BUILD_TYPE=Release',
        '-DGUI=ON', '-DWEBUI=ON', "-DTESTING=$testing",
        '-DMSVC_RUNTIME_DYNAMIC=ON',
        "-DLibtorrentRasterbar_DIR=$($libtorrentInfo.cmake_package_dir)"
    )
    Invoke-BuildTool 'cmake.exe' $configureArguments
    Invoke-BuildTool 'python.exe' @(
        (Join-Path $PSScriptRoot 'verify-static-link.py'),
        '--build-dir', $buildPath, '--manifest', $libtorrentResult
    )
    Invoke-BuildTool 'cmake.exe' @('--build', $buildPath, '--parallel', "$BuildJobs")
    if (-not $NoTests)
    {
        Invoke-BuildTool 'cmake.exe' @('--build', $buildPath, '--target', 'check', '--parallel', "$BuildJobs")
    }
    Invoke-BuildTool 'cmake.exe' @('--install', $buildPath, '--prefix', $stagePath)

    # CMake installs qBittorrent and qt.conf but does not deploy Qt or third-party DLLs.
    foreach ($runtimePath in $runtimePaths)
    {
        $resolvedRuntimePath = (Resolve-Path -LiteralPath $runtimePath).Path
        Get-ChildItem -LiteralPath $resolvedRuntimePath -Filter '*.dll' -File |
            Copy-Item -Destination $stageBin
    }
    Invoke-BuildTool $deployQt @(
        '--release', '--no-compiler-runtime',
        '--no-system-d3d-compiler', '--no-system-dxc-compiler', '--no-opengl-sw',
        '--dir', $stageBin,
        '--plugindir', (Join-Path $stageBin 'plugins'),
        '--translationdir', (Join-Path $stageBin 'translations'),
        (Join-Path $stageBin 'qbittorrent.exe')
    )
}
finally
{
    $env:PATH = $previousToolPath
}
$qtConfiguration = "[Paths]`nPlugins = plugins`nTranslations = translations`n"
[System.IO.File]::WriteAllText((Join-Path $stageBin 'qt.conf'), $qtConfiguration,
    [System.Text.UTF8Encoding]::new($false))
Copy-Item -LiteralPath (Join-Path $sourcePath 'COPYING') -Destination (Join-Path $stagePath 'COPYING')
Invoke-BuildTool 'python.exe' @((Join-Path $PSScriptRoot 'public-manifest.py'), $libtorrentResult,
    (Join-Path $stagePath 'libtorrent-build.json'))
Write-Output "Package staged in $stagePath. Install the official Microsoft VC++ 2022 x64 Redistributable before running it."
