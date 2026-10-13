param(
    [string]$DelphiRoot = 'C:\Program Files (x86)\Embarcadero\Studio\19.0',
    [switch]$Test
)
$ErrorActionPreference = 'Stop'
$compiler = Join-Path $DelphiRoot 'bin\dcc32.exe'
$rtl = Join-Path $DelphiRoot 'lib\win32\release'
if (-not (Test-Path -LiteralPath $compiler)) { throw "Delphi compiler not found: $compiler" }
$clients = @(
    @{ Folder='PMDG737'; Program='PMDG737FMC'; Screen='PMDG737Screen' },
    @{ Folder='PMDG777'; Program='PMDG777FMC'; Screen='PMDG777Screen' },
    @{ Folder='FBWA320'; Program='FBWA320MCDU'; Screen='FBWA320Screen' },
    @{ Folder='FenixA320'; Program='FenixA320MCDU'; Screen='FenixA320Screen' },
    @{ Folder='iFly737MAX'; Program='iFlyFMC'; Screen='iFlyScreen' }
)
$flatStage = Join-Path $PSScriptRoot 'packages\All'
$flatAssets = Join-Path $flatStage 'assets'
$archiveAssets = Join-Path $PSScriptRoot 'packages\Archive\assets'
New-Item -ItemType Directory -Path $archiveAssets -Force | Out-Null
New-Item -ItemType Directory -Path $flatAssets -Force | Out-Null
foreach ($client in $clients) {
    $folder = Join-Path $PSScriptRoot $client.Folder
    Push-Location $folder
    try {
        New-Item -ItemType Directory -Path 'build' -Force | Out-Null
        & $compiler -B -Q "-U$rtl;..\Common" '-N0build' '-Ebuild' ($client.Program+'.dpr')
        if ($LASTEXITCODE -ne 0) { throw "Build failed: $($client.Folder)" }
        & $compiler -B -Q "-U$rtl;..\Common" '-N0build' '-Ebuild' ($client.Screen+'.dpr')
        if ($LASTEXITCODE -ne 0) { throw "Screen build failed: $($client.Folder)" }
        $stage = Join-Path $PSScriptRoot ('packages\'+$client.Folder)
        New-Item -ItemType Directory -Path $stage -Force | Out-Null
        Copy-Item -LiteralPath ('build\'+$client.Program+'.exe') -Destination $stage -Force
        try { Copy-Item -LiteralPath ('build\'+$client.Program+'.exe') -Destination ($client.Program+'.exe') -Force }
        catch { Write-Warning "EXE is in use; the updated version is in the ZIP and packages folder." }
        Copy-Item -LiteralPath ('build\'+$client.Screen+'.exe') -Destination $stage -Force
        try { Copy-Item -LiteralPath ('build\'+$client.Screen+'.exe') -Destination $flatStage -Force }
        catch { Write-Warning 'Running EXE in All could not be replaced; use the updated ZIP after closing it.' }
        Copy-Item -LiteralPath ('build\'+$client.Screen+'.exe') -Destination ($client.Screen+'.exe') -Force
        $stageAssets = Join-Path $stage 'assets'
        New-Item -ItemType Directory -Path $stageAssets -Force | Out-Null
        # Remove only obsolete generated asset names from previous packages.
        foreach ($obsolete in @('cdu.png', 'button_click.wav')) {
            $oldAsset = Join-Path $stageAssets $obsolete
            if (Test-Path -LiteralPath $oldAsset) { Remove-Item -LiteralPath $oldAsset }
        }
        foreach ($asset in Get-ChildItem -LiteralPath 'assets' -File) {
            Copy-Item -LiteralPath $asset.FullName -Destination $stageAssets -Force
            Copy-Item -LiteralPath $asset.FullName -Destination $archiveAssets -Force
            $destination = Join-Path $flatAssets $asset.Name
            if ((Test-Path -LiteralPath $destination) -and
                ((Get-FileHash -LiteralPath $destination).Hash -ne (Get-FileHash -LiteralPath $asset.FullName).Hash)) {
                # Aircraft assets have unique names; only the shared font repeats.
                if ($asset.Name -eq 'B612Mono-Bold.ttf') { throw 'Aircraft font files differ' }
            }
            if (-not (Test-Path -LiteralPath $destination) -or
                ((Get-FileHash -LiteralPath $destination).Hash -ne (Get-FileHash -LiteralPath $asset.FullName).Hash)) {
                Copy-Item -LiteralPath $asset.FullName -Destination $flatAssets -Force
            }
        }
        try { Copy-Item -LiteralPath ('build\'+$client.Program+'.exe') -Destination $flatStage -Force }
        catch { Write-Warning 'Running EXE in All could not be replaced; use the updated ZIP after closing it.' }
        Copy-Item -LiteralPath 'README.md' -Destination $stage -Force
        Compress-Archive -LiteralPath (Join-Path $folder ('build\'+$client.Program+'.exe')),(Join-Path $folder ('build\'+$client.Screen+'.exe')),(Join-Path $stage 'assets'),(Join-Path $stage 'README.md') `
            -DestinationPath ($client.Folder+'-Windows.zip') -Force
    } finally { Pop-Location }
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README.md') -Destination $flatStage -Force
# Archive build outputs: deployed EXEs in All may currently be running.
$flatFiles = @($clients | ForEach-Object { Join-Path $PSScriptRoot ($_.Folder+'\build\'+$_.Program+'.exe'); Join-Path $PSScriptRoot ($_.Folder+'\build\'+$_.Screen+'.exe') })
$serverFiles = @('FlightPadFMCServer.exe', 'SDK2020\SimConnect.dll', 'SDK2024\SimConnect.dll')
$serverStage = Join-Path $PSScriptRoot 'packages\Archive\server'
$distRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'dist'
foreach ($relative in $serverFiles) {
    foreach ($targetRoot in @($serverStage, (Join-Path $flatStage 'server'))) {
        $target = Join-Path $targetRoot $relative
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $distRoot $relative) -Destination $target -Force
    }
}
$flatFiles += $archiveAssets, (Join-Path $flatStage 'README.md'), $serverStage
Compress-Archive -LiteralPath $flatFiles -DestinationPath `
    (Join-Path $PSScriptRoot 'packages\FlightPadFMC-Windows.zip') -Force
if ($Test) {
    Push-Location (Join-Path $PSScriptRoot 'tests')
    try {
        foreach ($client in $clients) {
            $out = 'build\'+$client.Folder
            New-Item -ItemType Directory -Path $out -Force | Out-Null
            & $compiler -B -Q "-U$rtl;..\Common;..\$($client.Folder)" "-N0$out" "-E$out" ClientTests.dpr
            if ($LASTEXITCODE -ne 0) { throw "Test build failed: $($client.Folder)" }
            # The entry-point regression also constructs ScreenMain with EXE-relative assets.
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot ($client.Folder+'\assets')) -Destination $out -Recurse -Force
            & $compiler -B -Q "-U$rtl;..\Common;..\$($client.Folder)" "-N0$out" "-E$out" ScreenTests.dpr
            if ($LASTEXITCODE -ne 0) { throw 'Screen test build failed' }
            & (Join-Path $PWD ($out+'\ScreenTests.exe')) $flatStage $PWD.Path
            if ($LASTEXITCODE -ne 0) { throw 'Screen tests failed' }
        }
        & $compiler -B -Q "-U$rtl;..\Common" '-N0build' '-Ebuild' DiscoveryTests.dpr
        if ($LASTEXITCODE -ne 0) { throw 'Discovery test build failed' }
        python discovery_tests.py
        if ($LASTEXITCODE -ne 0) { throw 'Discovery tests failed' }
        python client_tests.py $flatStage
        if ($LASTEXITCODE -ne 0) { throw 'Client integration tests failed' }
    } finally { Pop-Location }
}
Write-Host 'Built ten clients and packages/FlightPadFMC-Windows.zip.'
