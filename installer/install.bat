@echo off
setlocal
set "G=%ProgramFiles(x86)%\Steam\steamapps\common\Ready Or Not"
if not exist "%G%\ReadyOrNot\Binaries\Win64" set "G=E:\SteamLibrary\steamapps\common\Ready Or Not"
if not exist "%G%\ReadyOrNot\Binaries\Win64" set /p G=Paste your "Ready Or Not" folder (Steam: right-click game ^> Manage ^> Browse local files): 
set "W=%G%\ReadyOrNot\Binaries\Win64"
if not exist "%W%" (echo Could not find %W% & pause & exit /b 1)
xcopy /E /I /Y "%~dp0payload\*" "%W%\" >nul
echo Suspect Mode installed to %W%
echo Settings: %W%\ue4ss\Mods\RonSuspect\Scripts\config.lua
pause
