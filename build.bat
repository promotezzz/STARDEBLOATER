@echo off
setlocal enabledelayedexpansion

echo ==================================================
echo   ???? PACKAGING stardebloat REPO ????
echo ==================================================
echo.

cd /d "%~dp0"

echo 1. Setting up temporary release directory...
if exist "release" rmdir /s /q "release"
mkdir "release"

echo.
echo 2. Copying files to release folder...
xcopy /e /y /q "Assets" "release\Assets\" >nul
xcopy /e /y /q "Config" "release\Config\" >nul
xcopy /e /y /q "Regfiles" "release\Regfiles\" >nul
xcopy /e /y /q "Schemas" "release\Schemas\" >nul
xcopy /e /y /q "Scripts" "release\Scripts\" >nul
copy /y "LICENSE" "release\" >nul
copy /y "runme.bat" "release\" >nul
copy /y "stardebloat.ps1" "release\" >nul

echo.
echo 3. Compressing into stardebloat.zip...
if exist "stardebloat.zip" del /q "stardebloat.zip"
powershell -Command "Compress-Archive -Path 'release\*' -DestinationPath 'stardebloat.zip' -Force"
if %errorLevel% neq 0 (
    echo.
    echo ??? ERROR: Packaging failed!
    exit /b %errorLevel%
)

echo.
echo 4. Cleaning up temporary release directory...
rmdir /s /q "release"

echo.
echo ==================================================
echo   ???? SUCCESS: stardebloat.zip generated ????
echo ==================================================
echo You can find the zip package at:
echo   %cd%\stardebloat.zip
echo.
pause



