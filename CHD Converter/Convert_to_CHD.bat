@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem ============================================================
rem RetroAchievements CHD Auto Converter
rem ------------------------------------------------------------
rem Put this BAT beside chdman.exe.
rem Put ROMs inside the matching system folders.
rem Run this BAT and choose option 1.
rem
rem Compatibility-first defaults:
rem - 3DO, NEC PC-FX, and NEC TurboGrafx-CD use default CHD compression.
rem - All other CHD-compatible RA folders here use ZSTD.
rem - PS2 uses one folder: .cue = createcd ZSTD, .iso = createdvd ZSTD.
rem - Loose .bin files are ignored. Use the matching .cue file.
rem
rem Progress behavior:
rem - chdman output is shown live so the window does not look frozen.
rem - The log records each file, command mode, and final OK/SKIP/FAILED status.
rem ============================================================

set "ROOT=%~dp0"
set "CHDMAN=%ROOT%chdman.exe"
set "LOGDIR=%ROOT%_Logs"
set "LOG=%LOGDIR%\CHD_Converter.log"

set /a FOUND=0
set /a CONVERTED=0
set /a SKIPPED=0
set /a FAILED=0
set /a TOTAL_FOUND=0
set /a TOTAL_TO_CONVERT=0
set /a CURRENT=0

if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>nul

if not exist "%CHDMAN%" (
    where chdman.exe >nul 2>nul
    if errorlevel 1 (
        echo.
        echo ERROR: chdman.exe was not found.
        echo.
        echo Place chdman.exe in the same folder as this BAT, or add chdman.exe to PATH.
        echo.
        pause
        exit /b 1
    ) else (
        set "CHDMAN=chdman.exe"
    )
)

call :EnsureFolders

if /I "%~1"=="/AUTO" goto ConvertAll
if /I "%~1"=="/RUN" goto ConvertAll

:MainMenu
cls
echo ============================================================
echo RetroAchievements CHD Auto Converter
echo ============================================================
echo.
echo Root folder:
echo %ROOT%
echo.
echo chdman:
echo %CHDMAN%
echo.
echo 1 - Convert all system folders
echo 2 - Show folder/method list
echo 3 - Verify chdman.exe
echo 4 - Exit
echo.
choice /C 1234 /N /M "Choose an option: "
if errorlevel 4 goto End
if errorlevel 3 goto VerifyCHDMan
if errorlevel 2 goto ShowMethods
if errorlevel 1 goto ConvertAll

goto MainMenu

:VerifyCHDMan
cls
echo ============================================================
echo chdman verification
echo ============================================================
echo.
echo Using:
echo %CHDMAN%
echo.
"%CHDMAN%" >nul 2>nul
if errorlevel 1 (
    echo chdman.exe was found. Some versions return a non-zero code when run without arguments.
) else (
    echo chdman.exe was found and launched successfully.
)
echo.
pause
goto MainMenu

:ShowMethods
cls
echo ============================================================
echo Folder / conversion method list
echo ============================================================
echo.
echo DEFAULT/STANDARD createcd:
echo   3DO Interactive Multiplayer     *.cue, *.iso
echo   NEC PC-FX                       *.cue
echo   NEC TurboGrafx-CD               *.cue
echo.
echo ZSTD createcd:
echo   Sega CD                         *.cue
echo   Sega Dreamcast                  *.gdi, *.cue
echo   Sega Saturn                     *.cue
echo   SNK Neo Geo CD                  *.cue
echo   Sony PlayStation                *.cue
echo   Sony PlayStation 2              *.cue
echo.
echo ZSTD createdvd:
echo   Sony PlayStation 2              *.iso
echo   Sony PlayStation Portable       *.iso
echo.
echo Notes:
echo   - Output CHDs are created beside the source files.
echo   - Existing CHDs are skipped.
echo   - Source files are never deleted or moved by this BAT.
echo   - Loose .bin files are ignored; convert from the matching .cue.
echo   - chdman progress is shown live during conversion.
echo.
pause
goto MainMenu

:ConvertAll
cls
echo ============================================================
echo RetroAchievements CHD Auto Converter - Running
echo ============================================================
echo.

set /a FOUND=0
set /a CONVERTED=0
set /a SKIPPED=0
set /a FAILED=0
set /a TOTAL_FOUND=0
set /a TOTAL_TO_CONVERT=0
set /a CURRENT=0

echo Scanning folders...
call :CountAll

echo.
echo Candidates found: %TOTAL_FOUND%
echo Need conversion:  %TOTAL_TO_CONVERT%
echo.

echo.>>"%LOG%"
echo ============================================================>>"%LOG%"
echo Run started: %DATE% %TIME%>>"%LOG%"
echo Root: %ROOT%>>"%LOG%"
echo chdman: %CHDMAN%>>"%LOG%"
echo Candidates found: %TOTAL_FOUND%>>"%LOG%"
echo Need conversion: %TOTAL_TO_CONVERT%>>"%LOG%"
echo ============================================================>>"%LOG%"

if %TOTAL_FOUND% EQU 0 (
    echo No supported source files were found in the system folders.
    echo.
    echo Put ROMs in the matching system folders, then run again.
    echo.
    pause
    goto MainMenu
)

if %TOTAL_TO_CONVERT% EQU 0 (
    echo All supported source files already have matching CHD files.
    echo Nothing to convert.
    echo.
    pause
    goto MainMenu
)

rem DEFAULT/STANDARD compression for compatibility-first folders.
call :ProcessCDDefault "3DO Interactive Multiplayer" "*.cue"
call :ProcessCDDefault "3DO Interactive Multiplayer" "*.iso"
call :ProcessCDDefault "NEC PC-FX" "*.cue"
call :ProcessCDDefault "NEC TurboGrafx-CD" "*.cue"

rem ZSTD CD CHDs.
call :ProcessCDZstd "Sega CD" "*.cue"
call :ProcessCDZstd "Sega Dreamcast" "*.gdi"
call :ProcessCDZstd "Sega Dreamcast" "*.cue"
call :ProcessCDZstd "Sega Saturn" "*.cue"
call :ProcessCDZstd "SNK Neo Geo CD" "*.cue"
call :ProcessCDZstd "Sony PlayStation" "*.cue"
call :ProcessCDZstd "Sony PlayStation 2" "*.cue"

rem ZSTD DVD CHDs.
call :ProcessDVDZstd "Sony PlayStation 2" "*.iso"
call :ProcessDVDZstd "Sony PlayStation Portable" "*.iso"

echo.>>"%LOG%"
echo Summary: Found=%FOUND% Converted=%CONVERTED% Skipped=%SKIPPED% Failed=%FAILED%>>"%LOG%"
echo Run finished: %DATE% %TIME%>>"%LOG%"

echo.
echo ============================================================
echo Done
echo ============================================================
echo Found:     %FOUND%
echo Converted: %CONVERTED%
echo Skipped:   %SKIPPED%
echo Failed:    %FAILED%
echo.
echo Log file:
echo %LOG%
echo.
if %FAILED% GTR 0 (
    echo Some conversions failed. Check the log above.
    echo Partial failed CHDs are deleted automatically when detected.
    echo.
)
pause
goto MainMenu

:CountAll
call :CountFiles "3DO Interactive Multiplayer" "*.cue"
call :CountFiles "3DO Interactive Multiplayer" "*.iso"
call :CountFiles "NEC PC-FX" "*.cue"
call :CountFiles "NEC TurboGrafx-CD" "*.cue"
call :CountFiles "Sega CD" "*.cue"
call :CountFiles "Sega Dreamcast" "*.gdi"
call :CountFiles "Sega Dreamcast" "*.cue"
call :CountFiles "Sega Saturn" "*.cue"
call :CountFiles "SNK Neo Geo CD" "*.cue"
call :CountFiles "Sony PlayStation" "*.cue"
call :CountFiles "Sony PlayStation 2" "*.cue"
call :CountFiles "Sony PlayStation 2" "*.iso"
call :CountFiles "Sony PlayStation Portable" "*.iso"
exit /b 0

:CountFiles
set "SYSTEMDIR=%ROOT%%~1"
set "PATTERN=%~2"
if not exist "%SYSTEMDIR%" exit /b 0
for /r "%SYSTEMDIR%" %%F in (%PATTERN%) do call :CountOne "%%~fF"
exit /b 0

:CountOne
set "COUNT_INPUT=%~1"
set "COUNT_OUTPUT=%~dpn1.chd"
set /a TOTAL_FOUND+=1
if not exist "%COUNT_OUTPUT%" set /a TOTAL_TO_CONVERT+=1
exit /b 0

:ProcessCDDefault
set "FOLDER=%~1"
set "PATTERN=%~2"
set "SYSTEMDIR=%ROOT%%~1"
if not exist "%SYSTEMDIR%" exit /b 0

echo.
echo [CD DEFAULT] %FOLDER% - %PATTERN%
echo [CD DEFAULT] %FOLDER% - %PATTERN%>>"%LOG%"
for /r "%SYSTEMDIR%" %%F in (%PATTERN%) do call :ConvertOne CD_DEFAULT "%%~fF"
exit /b 0

:ProcessCDZstd
set "FOLDER=%~1"
set "PATTERN=%~2"
set "SYSTEMDIR=%ROOT%%~1"
if not exist "%SYSTEMDIR%" exit /b 0

echo.
echo [CD ZSTD] %FOLDER% - %PATTERN%
echo [CD ZSTD] %FOLDER% - %PATTERN%>>"%LOG%"
for /r "%SYSTEMDIR%" %%F in (%PATTERN%) do call :ConvertOne CD_ZSTD "%%~fF"
exit /b 0

:ProcessDVDZstd
set "FOLDER=%~1"
set "PATTERN=%~2"
set "SYSTEMDIR=%ROOT%%~1"
if not exist "%SYSTEMDIR%" exit /b 0

echo.
echo [DVD ZSTD] %FOLDER% - %PATTERN%
echo [DVD ZSTD] %FOLDER% - %PATTERN%>>"%LOG%"
for /r "%SYSTEMDIR%" %%F in (%PATTERN%) do call :ConvertOne DVD_ZSTD "%%~fF"
exit /b 0

:ConvertOne
set "MODE=%~1"
set "INPUT=%~2"
set "OUTPUT=%~dpn2.chd"

set /a FOUND+=1

if exist "%OUTPUT%" (
    set /a SKIPPED+=1
    echo [SKIP] "%OUTPUT%" already exists.
    echo [SKIP] "%OUTPUT%" already exists.>>"%LOG%"
    exit /b 0
)

set /a CURRENT+=1

echo.
echo ------------------------------------------------------------
echo Progress: %CURRENT% / %TOTAL_TO_CONVERT%
echo Mode:     %MODE%
echo Input:    %INPUT%
echo Output:   %OUTPUT%
echo ------------------------------------------------------------
echo.

echo [CONVERT] Progress=%CURRENT%/%TOTAL_TO_CONVERT% Mode=%MODE% Input="%INPUT%" Output="%OUTPUT%">>"%LOG%"

if /I "%MODE%"=="CD_DEFAULT" (
    echo Command: chdman createcd -i "source" -o "output"
    "%CHDMAN%" createcd -i "%INPUT%" -o "%OUTPUT%"
    goto CheckResult
)

if /I "%MODE%"=="CD_ZSTD" (
    echo Command: chdman createcd -i "source" -o "output" -c zstd,flac
    "%CHDMAN%" createcd -i "%INPUT%" -o "%OUTPUT%" -c zstd,flac
    goto CheckResult
)

if /I "%MODE%"=="DVD_ZSTD" (
    echo Command: chdman createdvd -i "source" -o "output" -c zstd
    "%CHDMAN%" createdvd -i "%INPUT%" -o "%OUTPUT%" -c zstd
    goto CheckResult
)

echo [FAILED] Unknown mode: %MODE%
echo [FAILED] Unknown mode: %MODE%>>"%LOG%"
set /a FAILED+=1
exit /b 1

:CheckResult
if errorlevel 1 (
    set /a FAILED+=1
    echo.
    echo [FAILED] "%INPUT%"
    echo [FAILED] "%INPUT%">>"%LOG%"
    if exist "%OUTPUT%" (
        del /f /q "%OUTPUT%" >nul 2>nul
        echo [CLEANUP] Deleted partial CHD: "%OUTPUT%"
        echo [CLEANUP] Deleted partial CHD: "%OUTPUT%">>"%LOG%"
    )
    exit /b 1
) else (
    set /a CONVERTED+=1
    echo.
    echo [OK] "%OUTPUT%"
    echo [OK] "%OUTPUT%">>"%LOG%"
    exit /b 0
)

:EnsureFolders
if not exist "%ROOT%3DO Interactive Multiplayer" mkdir "%ROOT%3DO Interactive Multiplayer" >nul 2>nul
if not exist "%ROOT%NEC PC-FX" mkdir "%ROOT%NEC PC-FX" >nul 2>nul
if not exist "%ROOT%NEC TurboGrafx-CD" mkdir "%ROOT%NEC TurboGrafx-CD" >nul 2>nul
if not exist "%ROOT%Sega CD" mkdir "%ROOT%Sega CD" >nul 2>nul
if not exist "%ROOT%Sega Dreamcast" mkdir "%ROOT%Sega Dreamcast" >nul 2>nul
if not exist "%ROOT%Sega Saturn" mkdir "%ROOT%Sega Saturn" >nul 2>nul
if not exist "%ROOT%SNK Neo Geo CD" mkdir "%ROOT%SNK Neo Geo CD" >nul 2>nul
if not exist "%ROOT%Sony PlayStation" mkdir "%ROOT%Sony PlayStation" >nul 2>nul
if not exist "%ROOT%Sony PlayStation 2" mkdir "%ROOT%Sony PlayStation 2" >nul 2>nul
if not exist "%ROOT%Sony PlayStation Portable" mkdir "%ROOT%Sony PlayStation Portable" >nul 2>nul
exit /b 0

:End
exit /b 0
