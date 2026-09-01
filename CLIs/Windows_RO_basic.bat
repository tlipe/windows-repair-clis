@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Windows Repair & Optimizer
color 0A

:: Self-elevate
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Solicitando privilegios de administrador...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "logdir=%~dp0logs"
if not exist "%logdir%" mkdir "%logdir%" >nul 2>&1

for /f "tokens=1-4 delims=/ " %%a in ("%date%") do (
    set "d1=%%a"
    set "d2=%%b"
    set "d3=%%c"
    set "d4=%%d"
)
set "stamp=%date:/=-%_%time::=-%"
set "stamp=%stamp: =0%"
set "stamp=%stamp:.=-%"
set "log=%logdir%\repair_%stamp%.log"

:menu
cls
echo ============================================================
echo              WINDOWS REPAIR ^& OPTIMIZER (Basic)
echo ============================================================
echo.
echo  [1] Reparo completo (recomendado)
echo      DISM + SFC + CHKDSK + limpeza de componentes
echo.
echo  [2] Reparar arquivos e imagem do Windows
echo      DISM + SFC
echo.
echo  [3] Verificar disco do sistema
echo      CHKDSK /scan
echo.
echo  [4] Limpeza segura
echo      Temporarios + WinSxS substituido
echo.
echo  [5] Reparar rede
echo      Flush DNS + reset Winsock
echo.
echo  [6] Gerar relatorio do SFC
echo.
echo  [7] Abrir logs
echo.
echo  [0] Sair
echo.
set /p "opt=Input: "

if "%opt%"=="1" goto full
if "%opt%"=="2" goto systemrepair
if "%opt%"=="3" goto disk
if "%opt%"=="4" goto cleanup
if "%opt%"=="5" goto network
if "%opt%"=="6" goto sfcreport
if "%opt%"=="7" goto logs
if "%opt%"=="0" goto end
goto menu


:showlast
powershell -NoProfile -Command "Get-Content -LiteralPath '%log%' -Tail 25" 2>nul
exit /b

:header
echo ============================================================ >> "%log%"
echo %date% %time% >> "%log%"
echo %~1 >> "%log%"
echo ============================================================ >> "%log%"
exit /b

:full
cls
call :header "REPARO COMPLETO"
echo [1/5] Verificando imagem do Windows...
DISM.exe /Online /Cleanup-Image /CheckHealth >> "%log%" 2>&1
call :showlast

echo.
echo [2/5] Analisando imagem do Windows...
DISM.exe /Online /Cleanup-Image /ScanHealth >> "%log%" 2>&1
call :showlast

echo.
echo [3/5] Reparando imagem do Windows...
DISM.exe /Online /Cleanup-Image /RestoreHealth >> "%log%" 2>&1
call :showlast

echo.
echo [4/5] Verificando arquivos protegidos...
sfc /scannow >> "%log%" 2>&1
call :showlast

echo.
echo [5/5] Verificando sistema de arquivos...
chkdsk %SystemDrive% /scan >> "%log%" 2>&1
call :showlast

echo.
echo Limpando componentes substituidos...
DISM.exe /Online /Cleanup-Image /StartComponentCleanup >> "%log%" 2>&1
call :showlast

call :done
goto menu

:systemrepair
cls
call :header "REPARO DA IMAGEM E ARQUIVOS DO WINDOWS"
echo Verificando saude da imagem...
DISM.exe /Online /Cleanup-Image /CheckHealth >> "%log%" 2>&1
call :showlast
DISM.exe /Online /Cleanup-Image /ScanHealth >> "%log%" 2>&1
call :showlast

echo.
echo Reparando imagem...
DISM.exe /Online /Cleanup-Image /RestoreHealth >> "%log%" 2>&1
call :showlast

echo.
echo Verificando arquivos protegidos...
sfc /scannow >> "%log%" 2>&1
call :showlast

call :done
goto menu

:disk
cls
call :header "VERIFICACAO DE DISCO"
echo Verificando %SystemDrive% sem desmontar o volume...
chkdsk %SystemDrive% /scan >> "%log%" 2>&1
call :showlast
call :done
goto menu

:cleanup
cls
call :header "LIMPEZA SEGURA"
echo Limpando temporarios do usuario...
del /f /s /q "%TEMP%\*" >> "%log%" 2>&1
for /d %%d in ("%TEMP%\*") do rd /s /q "%%d" >> "%log%" 2>&1

echo.
echo Limpando temporarios do Windows...
del /f /s /q "%SystemRoot%\Temp\*" >> "%log%" 2>&1
for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" >> "%log%" 2>&1

echo.
echo Limpando componentes substituidos do Windows...
DISM.exe /Online /Cleanup-Image /StartComponentCleanup >> "%log%" 2>&1
call :showlast

echo.
echo Observacao: arquivos em uso sao ignorados automaticamente.
call :done
goto menu

:network
cls
call :header "REPARO DE REDE"
echo Limpando cache DNS...
ipconfig /flushdns >> "%log%" 2>&1
call :showlast

echo.
echo Restaurando catalogo Winsock...
netsh winsock reset >> "%log%" 2>&1
call :showlast

echo.
echo Reinicie o Windows para concluir o reset Winsock.
call :done
goto menu

:sfcreport
cls
call :header "RELATORIO SFC"
set "report=%~dp0sfcdetails.txt"
findstr /c:"[SR]" "%windir%\Logs\CBS\CBS.log" > "%report%"
echo Relatorio criado em:
echo "%report%"
echo Arquivo: "%report%" >> "%log%"
pause
goto menu

:logs
if not exist "%logdir%" mkdir "%logdir%"
start "" explorer.exe "%logdir%"
goto menu

:done
echo.
echo ============================================================
echo Operacao concluida.
echo Log: "%log%"
echo ============================================================
echo.
pause
exit /b

:end
endlocal
exit /b
