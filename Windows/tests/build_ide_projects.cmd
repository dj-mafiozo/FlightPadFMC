@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\19.0\bin\rsvars.bat"
if errorlevel 1 exit /b 1
cd /d "%~dp0"
for %%P in (..\PMDG737\PMDG737FMC.dproj ..\PMDG777\PMDG777FMC.dproj ..\FBWA320\FBWA320MCDU.dproj ..\FenixA320\FenixA320MCDU.dproj ..\iFly737MAX\iFlyFMC.dproj ..\PMDG737\PMDG737Screen.dproj ..\PMDG777\PMDG777Screen.dproj ..\FBWA320\FBWA320Screen.dproj ..\FenixA320\FenixA320Screen.dproj ..\iFly737MAX\iFlyScreen.dproj) do (
  if not exist "build\ide\%%~nP" mkdir "build\ide\%%~nP"
  msbuild "%%P" /t:Build /p:Config=Release /p:Platform=Win32 "/p:DCC_ExeOutput=%~dp0build\ide\%%~nP" /verbosity:minimal /nologo
  if errorlevel 1 exit /b 1
)
