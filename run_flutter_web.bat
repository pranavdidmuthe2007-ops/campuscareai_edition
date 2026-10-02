@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>nul
if errorlevel 1 (
    if exist "C:\src\flutter\bin\flutter.bat" (
        set "PATH=C:\src\flutter\bin;%PATH%"
    ) else if exist "C:\Users\ASUS\flutter\bin\flutter.bat" (
        set "PATH=C:\Users\ASUS\flutter\bin;%PATH%"
    ) else (
        echo Flutter SDK not found on PATH.
        echo Install Flutter and add it to PATH, or update the path inside this script.
        exit /b 1
    )
)

echo Launching CampusCare Flutter app in Chrome...
flutter run -d chrome --web-port 3000
