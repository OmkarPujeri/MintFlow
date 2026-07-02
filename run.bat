@echo off
echo Starting MintFlow Backend...
cd /d "%~dp0backend"
call ..\venv\Scripts\uvicorn.exe app.main:app --reload --host 0.0.0.0 --port 8000
pause
