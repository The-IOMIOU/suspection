@echo off
setlocal
set "G=%ProgramFiles(x86)%\Steam\steamapps\common\Ready Or Not"
if not exist "%G%\ReadyOrNot\Binaries\Win64" set "G=E:\SteamLibrary\steamapps\common\Ready Or Not"
if not exist "%G%\ReadyOrNot\Binaries\Win64" set /p G=Paste your "Ready Or Not" folder (Steam: right-click game ^> Manage ^> Browse local files):
set "W=%G%\ReadyOrNot\Binaries\Win64"
if not exist "%W%" (echo Could not find %W% & pause & exit /b 1)

rem Another tool (ReShade, some overlays) may already use dwmapi.dll: keep a backup instead of silently overwriting it.
if exist "%W%\dwmapi.dll" if not exist "%W%\ue4ss" (
  copy /Y "%W%\dwmapi.dll" "%W%\dwmapi.dll.before-suspectmode" >nul
  echo NOTE: an existing dwmapi.dll was backed up as dwmapi.dll.before-suspectmode
)

xcopy /E /I /Y "%~dp0payload\*" "%W%\" >nul

rem Dev-only files that a copied (not installed) folder may have brought along. They are not part of the mod.
if exist "%W%\ue4ss\Mods\RonBridge" rmdir /S /Q "%W%\ue4ss\Mods\RonBridge"
if exist "%W%\ue4ss\Mods\RonDump" rmdir /S /Q "%W%\ue4ss\Mods\RonDump"

echo.
echo Suspect Mode installed to %W%
echo Settings: %W%\ue4ss\Mods\RonSuspect\Scripts\config.lua  (or press F8 in game)
echo Problems? See docs\TROUBLESHOOTING.md on the GitHub page.
pause
