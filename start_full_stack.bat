@echo off
setlocal
cd /d "%~dp0"

rem Clear stale listeners for the app ports before starting the stack.
for %%P in (8001 3000) do (
    for /f "tokens=5" %%A in ('netstat -ano -p tcp ^| findstr :%%P') do (
        if not "%%A"=="" (
            echo Stopping stale process on port %%P (PID %%A)
            taskkill /PID %%A /F >nul 2>&1
        )
    )
)

start "CampusCare API" cmd /k "%~dp0backend\run_backend.bat"

rem Wait until the API becomes reachable before launching the UI.
for /L %%I in (1,1,40) do (
    powershell -NoProfile -Command "$r = try { Invoke-WebRequest -Uri 'http://127.0.0.1:8001/' -UseBasicParsing -TimeoutSec 2 -ErrorAction Stop } catch { $null }; if ($r) { exit 0 } else { exit 1 }" >nul 2>&1
    if not errorlevel 1 goto backend_ready
    ping -n 2 127.0.0.1 >nul
)
:backend_ready

start "CampusCare Flutter" cmd /k "%~dp0run_flutter_web.bat"

echo CampusCare stack started successfully.
echo API: http://127.0.0.1:8001
echo App: http://localhost:3000
