@echo off
SETLOCAL EnableDelayedExpansion

set PROJECT_PATH=%1
set PROJECT_OUTPUT_PATH=%2
set PROJECT_CONFIGURATION=%3
set UCRT_DLL_PATH="%WindowsSdkVerBinPath%\x64\ucrt"
set VS_CRT_REDIST_WILDCARD_FOLDER= ("%VcToolsRedistDir%onecore\x64\Microsoft.VC*.CRT")
set DEFAULT_OUTPUT_PATH="%~dp0\bin\iotedgeoutput"

if "%PROJECT_OUTPUT_PATH%" == "" (
    set PROJECT_OUTPUT_PATH=%DEFAULT_OUTPUT_PATH%
)

if "%PROJECT_CONFIGURATION%" == "" (
    set PROJECT_CONFIGURATION="Release"
)

:: Check execution environment
if "%VSINSTALLDIR%" == "" (
    goto RunFromDevCmd
)

for /D %%A in %VS_CRT_REDIST_WILDCARD_FOLDER% do (
    call robocopy.exe "%%~A" %PROJECT_OUTPUT_PATH% /S /E >nul
    if !ERRORLEVEL! LEQ 8 (
        goto StageResistRelOk
    )
)
echo Error while staging debugger binaries. Exiting...
exit /b 1

:StageResistRelOk

call robocopy.exe %UCRT_DLL_PATH% %PROJECT_OUTPUT_PATH% /S /E >nul
if %ERRORLEVEL% GTR 8 (
    :: Non-fatal error, but debug binaries won't work
    echo Warning! Unable to stage UCRT dll, debug binaries will not run in the container.
)

echo Build project...
msbuild %PROJECT_PATH% /p:Configuration=%PROJECT_CONFIGURATION% /p:Platform="x64" /p:OutDir=%PROJECT_OUTPUT_PATH%

if not "%PROJECT_OUTPUT_PATH%" == "%DEFAULT_OUTPUT_PATH%" (
    call robocopy.exe %PROJECT_OUTPUT_PATH% %DEFAULT_OUTPUT_PATH% /IS /E >nul
    if %ERRORLEVEL% GTR 8 (
        echo Warning! Unable to copy binaries to %DEFAULT_OUTPUT_PATH%
        exit /b 1
    )
    else
    (
        exit /b 0
    )
)

goto :EOF

:RunFromDevCmd
echo.
echo  Please run the script in a Visual Studio Developer Command Prompt 
echo.
goto :EOF

:Usage
echo.
echo Usage:
echo.
echo    NanoDockerBuild.cmd [full-path-to-test-binaries]
echo.
goto :EOF