# SPDX-License-Identifier: GPL-3.0-or-later
[CmdletBinding()]
param([int] $BuildJobs = 4)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path -Parent $PSScriptRoot
$taskVcpkg = Join-Path $taskRoot 'build/deps/vcpkg'
$taskRevision = Get-Content -LiteralPath (Join-Path $taskRoot 'dependencies/vcpkg-revision.json') -Raw | ConvertFrom-Json
function Invoke-Checked([string] $Program, [string[]] $Arguments)
{
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Program zakończył się kodem $LASTEXITCODE." }
}
if (-not (Test-Path -LiteralPath $taskVcpkg))
{
    Invoke-Checked git @('clone', 'https://github.com/microsoft/vcpkg.git', $taskVcpkg)
    Invoke-Checked git @('-C', $taskVcpkg, 'checkout', '--detach', $taskRevision.commit)
}
$taskActualRevision = (& git -C $taskVcpkg rev-parse HEAD).Trim()
if ($taskActualRevision -ne $taskRevision.commit) { throw 'Istniejące vcpkg ma inną rewizję. Wskaż osobny katalog budowania.' }
Invoke-Checked (Join-Path $taskVcpkg 'bootstrap-vcpkg.bat') @('-disableMetrics')
$env:VCPKG_MAX_CONCURRENCY = "$BuildJobs"
Invoke-Checked (Join-Path $taskVcpkg 'vcpkg.exe') @('install', 'boost', 'openssl', 'zlib',
    '--triplet=x64-windows-static-md-release', "--overlay-triplets=$PSScriptRoot/triplets",
    "--overlay-ports=$taskRoot/dependencies/vcpkg-ports", '--disable-metrics')
Write-Output "Zależności przygotowane w $taskVcpkg/installed/x64-windows-static-md-release."
