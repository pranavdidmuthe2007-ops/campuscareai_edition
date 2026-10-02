@echo off
setlocal
cd /d "%~dp0"

if exist "..\.venv\Scripts\python.exe" (
    call "..\.venv\Scripts\activate.bat"
) else (
    echo Python virtual environment not found at ..\.venv
    echo Please create or restore the virtual environment first.
    exit /b 1
)

echo Seeding demo data...
python seed_data.py

echo Starting CampusCare API on http://127.0.0.1:8001
python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8001
