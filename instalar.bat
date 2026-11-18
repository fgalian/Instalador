@echo off
setlocal
cd /d "%~dp0"

set "INSTALLER_SCRIPT=%~dp0InstaladorSoftware.ps1"
if not exist "%INSTALLER_SCRIPT%" (
    echo No se encuentra InstaladorSoftware.ps1 en esta carpeta.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -STA -File ""' + $env:INSTALLER_SCRIPT + '""') -ErrorAction Stop } catch { Write-Error $_; exit 1 }"
if errorlevel 1 (
    echo No se pudo iniciar el instalador. Comprueba que aceptaste el aviso de UAC.
    pause
    exit /b 1
)
