@echo off
setlocal EnableDelayedExpansion

set install_location=D:\Program Files

set install_list_file=%~dp0\install_package_list.txt
set failed_list=

for /F "tokens=1,2 delims= " %%i in (%install_list_file%) do (
    echo ------------------------------------
    echo Installing %%i...
    echo ------------------------------------
    winget install %%j -i -l "%install_location%\%%i"
    if %ERRORLEVEL% EQU 0 (
        echo %%i installed successfully.
    ) else (
        echo %%i install failed!!!!!!!
        set failed_list=!failed_list! %%i
    )
    echo.
)

if not "!failed_list!"==""  (
    echo Install failed list: 
    for %%j in (%failed_list%) do echo %%j
)

pause
