@echo off
set /p G=Paste your "Ready Or Not" folder: 
del "%G%\ReadyOrNot\Binaries\Win64\dwmapi.dll"
rmdir /S /Q "%G%\ReadyOrNot\Binaries\Win64\ue4ss"
echo Removed. & pause
