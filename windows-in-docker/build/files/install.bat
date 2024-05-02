@echo off
set LOGFILE=batch.log
call :LOG > %LOGFILE%
exit /B

:LOG
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "C:\OEM\create_task.ps1"