@echo off
setlocal
rem A PSModulePath inherited from PowerShell 7 makes Windows PowerShell load modules it cannot run.
set "PSModulePath="
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" %*
