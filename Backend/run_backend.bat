@echo off
title KidSafe Backend Server
echo ========================================================
echo   KIDSAFE REST API BACKEND - FASTAPI + SQLITE
echo ========================================================
echo Dang khoi dong may chu tai http://127.0.0.1:8000 ...
echo Tai lieu API Swagger UI: http://127.0.0.1:8000/docs
echo.
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause
