:: This script updates or installs a new version of Spyder
@echo off

:: Create variables from arguments
:parse
IF "%~1"=="" GOTO endparse
IF "%~1"=="-p" set prefix=%~2& SHIFT
IF "%~1"=="-i" set install_exe=%~2& SHIFT
IF "%~1"=="-c" set conda=%~2& SHIFT
IF "%~1"=="-v" set spy_ver=%~2& SHIFT
SHIFT
GOTO parse
:endparse

:: Enforce encoding
chcp 65001>nul

echo =========================================================
echo Updating Spyder
echo ---------------
echo.
echo IMPORTANT: Do not close this window until it has finished
echo =========================================================
echo.

call :wait_for_spyder_quit

IF not "%conda%"=="" IF not "%spy_ver%"=="" (
    call :update_subroutine
    call :launch_spyder
    goto exit
)

IF not "%install_exe%"=="" (
    call :install_subroutine
    goto exit
)

:exit
exit %ERRORLEVEL%

:install_subroutine
    echo Installing Spyder from: %install_exe%

    :: Uninstall Spyder
    for %%I in ("%prefix%\..\..") do set "conda_root=%%~fI"

    echo Install will proceed after the current Spyder version is uninstalled.
    start %conda_root%\Uninstall-Spyder.exe

    :: Must wait for uninstaller to appear on tasklist
    :wait_for_uninstall_start
    tasklist /fi "ImageName eq Un_A.exe" /fo csv 2>NUL | find /i "Un_A.exe">NUL
    IF "%ERRORLEVEL%"=="1" (
        timeout /t 1 /nobreak > nul
        goto wait_for_uninstall_start
    )
    echo Uninstall in progress...

    :wait_for_uninstall
    timeout /t 1 /nobreak > nul
    tasklist /fi "ImageName eq Un_A.exe" /fo csv 2>NUL | find /i "Un_A.exe">NUL
    IF "%ERRORLEVEL%"=="0" goto wait_for_uninstall
    echo Uninstall complete.

    start %install_exe%
    goto :EOF

:update_subroutine
    echo Updating Spyder

    %conda% install -p %prefix% -y spyder=%spy_ver%
    set /P =Press return to exit...
    goto :EOF

:wait_for_spyder_quit
    echo Waiting for Spyder to quit...
    :loop
    tasklist /v /fi "ImageName eq pythonw.exe" /fo csv 2>NUL | find "Spyder">NUL
    IF "%ERRORLEVEL%"=="0" (
        timeout /t 1 /nobreak > nul
        goto loop
    )
    echo Spyder is quit.
    goto :EOF

:launch_spyder
    for %%C in ("%conda%") do set scripts=%%~dpC
    set pythonexe=%scripts%..\python.exe
    set menuinst=%scripts%menuinst_cli.py
    if exist "%prefix%\.nonadmin" (set mode=user) else set mode=system
    for /f "delims=" %%s in ('%pythonexe% %menuinst% shortcut --mode=%mode%') do set "shortcut_path=%%~s"

    start "" /B "%shortcut_path%"
    goto :EOF
