param([string]$DelphiRoot = 'C:\Program Files (x86)\Embarcadero\Studio\19.0')
$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    $compiler = Join-Path $DelphiRoot 'bin\dcc32.exe'
    $units = Join-Path $DelphiRoot 'lib\win32\release'
    & $compiler -B -Q "-U$units;..\Common" iFlyFMC.dpr
    if ($LASTEXITCODE -ne 0) { throw 'Delphi build failed' }
    Write-Host "Built $PSScriptRoot\iFlyFMC.exe (keep the assets folder beside the EXE)."
} finally { Pop-Location }
