@echo off
title Easy Read Studio Admin Server
cd /d "%~dp0"
echo =======================================================
echo   Starting Easy Read Studio Admin & API Server
echo   Local URL:    http://localhost:8000/admin/login
echo   Network URL:  http://172.31.2.46:8000/admin/login
echo   Admin Email:  admin@easyword.com
echo   Password:     admin123456
echo =======================================================
:loop
php -S 0.0.0.0:8000 -t public server.php
timeout /t 1 >nul
goto loop
