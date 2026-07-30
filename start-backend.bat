@echo off
title Urban Service — Backend API
echo ============================================
echo   Urban Service App — Backend Server
echo   Running on: http://localhost:5000
echo ============================================
echo.
cd /d "%~dp0backend"
node src/server.js
pause
