@echo off
cd /d "%~dp0"
echo Starting Puzzle Cam... allow the camera when Chrome asks.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"
