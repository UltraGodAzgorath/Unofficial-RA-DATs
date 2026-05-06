@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem ============================================================
rem RetroAchievements CHD Auto Converter
rem ------------------------------------------------------------
rem Put this BAT beside chdman.exe.
rem Put ROMs inside the matching system folders.
rem
rem Compatibility-first defaults:
rem - 3DO, NEC PC-FX, and NEC TurboGrafx-CD use default CHD compression.
rem - All other CHD-compatible RA folders here use ZSTD.
rem - PS2 uses one folder: .cue = createcd ZSTD, .iso = createdvd ZSTD.
rem - Loose .bin files are ignored. Use the matching .cue file.
rem
rem Added checker/fixer:
rem - Uses chdman info -v to inspect existing CHD metadata.
rem - Detects CD CHD vs DVD CHD when metadata is available.
rem - Detects ZSTD vs standard/default compression.
rem - Can fix wrong compression by extracting to temp files and recompressing.
rem - Original CHDs are renamed to .backup_RANDOM.chd after a successful fix.
rem ============================================================

set "ROOT=%~dp0"
set "CHDMAN=%ROOT%chdman.exe"
set "LOGDIR=%ROOT%_Logs"
set "LOG=%LOGDIR%\CHD_Converter.log"

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
if /I "%~1"=="/CHECK" goto CheckCHDs
if /I "%~1"=="/FIX" goto FixCHDs

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
echo 1 - Convert all system folders to CHD
echo 2 - Check existing CHD format/compression
echo 3 - Fix wrong CHD compression
echo 4 - Show folder/method list
echo 5 - Verify chdman.exe
echo 6 - Exit
echo.
choice /C 123456 /N /M "Choose an option: "
if errorlevel 6 goto End
if errorlevel 5 goto VerifyCHDMan
if errorlevel 4 goto ShowMethods
if errorlevel 3 goto FixCHDs
if errorlevel 2 goto CheckCHDs
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
echo Existing CHD check/fix rules:
echo   3DO Interactive Multiplayer     CD CHD, standard/default compression
echo   NEC PC-FX                       CD CHD, standard/default compression
echo   NEC TurboGrafx-CD               CD CHD, standard/default compression
echo   Sega CD                         CD CHD, ZSTD compression
echo   Sega Dreamcast                  CD CHD, ZSTD compression
echo   Sega Saturn                     CD CHD, ZSTD compression
echo   SNK Neo Geo CD                  CD CHD, ZSTD compression
echo   Sony PlayStation                CD CHD, ZSTD compression
echo   Sony PlayStation 2              CD or DVD CHD, ZSTD compression
echo   Sony PlayStation Portable       DVD CHD, ZSTD compression
echo.
echo Notes:
echo   - Output CHDs are created beside the source files.
echo   - Existing CHDs are skipped during conversion.
echo   - Source files are never deleted or moved by this BAT.
echo   - Loose .bin files are ignored; convert from the matching .cue.
echo   - chdman progress is shown live during conversion and fixing.
echo   - Check/fix uses CHD metadata. Unknown CD/DVD type is logged and skipped by fixer.
echo.
pause
goto MainMenu

:ConvertAll
cls
echo ============================================================
echo RetroAchievements CHD Auto Converter - Convert
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
echo Convert run started: %DATE% %TIME%>>"%LOG%"
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
echo Convert summary: Found=%FOUND% Converted=%CONVERTED% Skipped=%SKIPPED% Failed=%FAILED%>>"%LOG%"
echo Convert run finished: %DATE% %TIME%>>"%LOG%"

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
set "INPUT=%~1"
set "OUTPUT=%~dpn1.chd"
set /a TOTAL_FOUND+=1
if not exist "%OUTPUT%" set /a TOTAL_TO_CONVERT+=1
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
echo Progress: %CURRENT% / %TOTAL_TO_CONVERT%
echo Mode:     %MODE%
echo Input:    %INPUT%
echo Output:   %OUTPUT%
echo [CONVERT] Mode=%MODE% Input="%INPUT%" Output="%OUTPUT%">>"%LOG%"

if /I "%MODE%"=="CD_DEFAULT" (
    "%CHDMAN%" createcd -i "%INPUT%" -o "%OUTPUT%"
    goto CheckConvertResult
)

if /I "%MODE%"=="CD_ZSTD" (
    "%CHDMAN%" createcd -i "%INPUT%" -o "%OUTPUT%" -c zstd,flac
    goto CheckConvertResult
)

if /I "%MODE%"=="DVD_ZSTD" (
    "%CHDMAN%" createdvd -i "%INPUT%" -o "%OUTPUT%" -c zstd
    goto CheckConvertResult
)

echo [FAILED] Unknown mode: %MODE%
echo [FAILED] Unknown mode: %MODE%>>"%LOG%"
set /a FAILED+=1
exit /b 1

:CheckConvertResult
if errorlevel 1 (
    set /a FAILED+=1
    echo [FAILED] "%INPUT%"
    echo [FAILED] "%INPUT%">>"%LOG%"
    if exist "%OUTPUT%" (
        del /f /q "%OUTPUT%" >nul 2>nul
        echo [CLEANUP] Deleted partial CHD: "%OUTPUT%">>"%LOG%"
    )
    exit /b 1
) else (
    set /a CONVERTED+=1
    echo [OK] "%OUTPUT%"
    echo [OK] "%OUTPUT%">>"%LOG%"
    exit /b 0
)

:CheckCHDs
cls
echo ============================================================
echo Existing CHD Format/Compression Check
echo ============================================================
echo.

set /a CHD_CHECKED=0
set /a CHD_OK=0
set /a CHD_WRONG=0
set /a CHD_UNKNOWN=0
set /a CHD_FIXABLE=0
set /a CHD_FIXED=0
set /a CHD_FIX_FAILED=0
set "CHECK_ACTION=CHECK"

echo.>>"%LOG%"
echo ============================================================>>"%LOG%"
echo CHD check started: %DATE% %TIME%>>"%LOG%"
echo ============================================================>>"%LOG%"

call :RunCHDScan CHECK

echo.>>"%LOG%"
echo CHD check summary: Checked=%CHD_CHECKED% OK=%CHD_OK% Wrong=%CHD_WRONG% Unknown=%CHD_UNKNOWN% Fixable=%CHD_FIXABLE%>>"%LOG%"
echo CHD check finished: %DATE% %TIME%>>"%LOG%"

echo.
echo ============================================================
echo Check complete
echo ============================================================
echo Checked: %CHD_CHECKED%
echo OK:      %CHD_OK%
echo Wrong:   %CHD_WRONG%
echo Unknown: %CHD_UNKNOWN%
echo Fixable wrong-compression CHDs: %CHD_FIXABLE%
echo.
echo Log file:
echo %LOG%
echo.
pause
goto MainMenu

:FixCHDs
cls
echo ============================================================
echo Fix Wrong CHD Compression
echo ============================================================
echo.
echo This will scan existing CHDs, extract fixable wrong-compression CHDs
echo to temporary files, then recompress them with the correct compression.
echo.
echo Original CHDs are not deleted. After a successful fix, the original CHD
echo is renamed to:
echo   game.backup_RANDOM.chd
echo.
echo Unknown CHD types are skipped. Wrong disc type for the folder is skipped.
echo Make sure you have enough free disk space before continuing.
echo.
choice /C YN /N /M "Continue with fixing wrong-compression CHDs? [Y/N]: "
if errorlevel 2 goto MainMenu

set /a CHD_CHECKED=0
set /a CHD_OK=0
set /a CHD_WRONG=0
set /a CHD_UNKNOWN=0
set /a CHD_FIXABLE=0
set /a CHD_FIXED=0
set /a CHD_FIX_FAILED=0
set "CHECK_ACTION=FIX"

echo.>>"%LOG%"
echo ============================================================>>"%LOG%"
echo CHD fix started: %DATE% %TIME%>>"%LOG%"
echo ============================================================>>"%LOG%"

call :RunCHDScan FIX

echo.>>"%LOG%"
echo CHD fix summary: Checked=%CHD_CHECKED% OK=%CHD_OK% Wrong=%CHD_WRONG% Unknown=%CHD_UNKNOWN% Fixable=%CHD_FIXABLE% Fixed=%CHD_FIXED% FixFailed=%CHD_FIX_FAILED%>>"%LOG%"
echo CHD fix finished: %DATE% %TIME%>>"%LOG%"

echo.
echo ============================================================
echo Fix complete
echo ============================================================
echo Checked:    %CHD_CHECKED%
echo OK:         %CHD_OK%
echo Wrong:      %CHD_WRONG%
echo Unknown:    %CHD_UNKNOWN%
echo Fixable:    %CHD_FIXABLE%
echo Fixed:      %CHD_FIXED%
echo Fix failed: %CHD_FIX_FAILED%
echo.
echo Log file:
echo %LOG%
echo.
pause
goto MainMenu

:RunCHDScan
set "CHECK_ACTION=%~1"

call :ProcessCHDFolder "3DO Interactive Multiplayer" "CD" "STANDARD"
call :ProcessCHDFolder "NEC PC-FX" "CD" "STANDARD"
call :ProcessCHDFolder "NEC TurboGrafx-CD" "CD" "STANDARD"

call :ProcessCHDFolder "Sega CD" "CD" "ZSTD"
call :ProcessCHDFolder "Sega Dreamcast" "CD" "ZSTD"
call :ProcessCHDFolder "Sega Saturn" "CD" "ZSTD"
call :ProcessCHDFolder "SNK Neo Geo CD" "CD" "ZSTD"
call :ProcessCHDFolder "Sony PlayStation" "CD" "ZSTD"

rem PS2 can be CD or DVD. Metadata decides extraction/fix method.
call :ProcessCHDFolder "Sony PlayStation 2" "ANY" "ZSTD"

call :ProcessCHDFolder "Sony PlayStation Portable" "DVD" "ZSTD"
exit /b 0

:ProcessCHDFolder
set "FOLDER=%~1"
set "EXPECTED_TYPE=%~2"
set "EXPECTED_COMP=%~3"
set "SYSTEMDIR=%ROOT%%~1"
if not exist "%SYSTEMDIR%" exit /b 0

echo.
echo [CHECK] %FOLDER%  Expected: %EXPECTED_TYPE% / %EXPECTED_COMP%
echo [CHECK] %FOLDER% Expected=%EXPECTED_TYPE%/%EXPECTED_COMP%>>"%LOG%"
for /r "%SYSTEMDIR%" %%F in (*.chd) do call :CheckOneCHD "%%~fF" "%EXPECTED_TYPE%" "%EXPECTED_COMP%" "%CHECK_ACTION%"
exit /b 0

:CheckOneCHD
set "CHD_FILE=%~1"
set "EXPECTED_TYPE=%~2"
set "EXPECTED_COMP=%~3"
set "ACTION=%~4"
set /a CHD_CHECKED+=1

call :DetectCHD "%CHD_FILE%"

set "STATUS=OK"
set "REASON="
set "FIXABLE=NO"

if /I "%DETECT_TYPE%"=="UNKNOWN" (
    set "STATUS=UNKNOWN"
    set "REASON=Could not detect CD/DVD CHD type from metadata"
    goto ReportCHDStatus
)

if /I not "%EXPECTED_TYPE%"=="ANY" (
    if /I not "%DETECT_TYPE%"=="%EXPECTED_TYPE%" (
        set "STATUS=WRONG"
        set "REASON=Wrong disc type for this folder"
        goto ReportCHDStatus
    )
)

if /I not "%DETECT_COMP%"=="%EXPECTED_COMP%" (
    set "STATUS=WRONG"
    set "REASON=Wrong compression"
    set "FIXABLE=YES"
    goto ReportCHDStatus
)

:ReportCHDStatus
if /I "%STATUS%"=="OK" (
    set /a CHD_OK+=1
    echo [OK]      %DETECT_TYPE% / %DETECT_COMP%  "%CHD_FILE%"
    echo [OK] Type=%DETECT_TYPE% Compression=%DETECT_COMP% "%CHD_FILE%">>"%LOG%"
    exit /b 0
)

if /I "%STATUS%"=="UNKNOWN" (
    set /a CHD_UNKNOWN+=1
    echo [UNKNOWN] %DETECT_TYPE% / %DETECT_COMP%  "%CHD_FILE%"
    echo [UNKNOWN] %REASON% Type=%DETECT_TYPE% Compression=%DETECT_COMP% "%CHD_FILE%">>"%LOG%"
    exit /b 0
)

set /a CHD_WRONG+=1
echo [WRONG]   %DETECT_TYPE% / %DETECT_COMP% should be %EXPECTED_TYPE% / %EXPECTED_COMP%  "%CHD_FILE%"
echo [WRONG] %REASON% Type=%DETECT_TYPE% Compression=%DETECT_COMP% Expected=%EXPECTED_TYPE%/%EXPECTED_COMP% "%CHD_FILE%">>"%LOG%"

if /I "%FIXABLE%"=="YES" (
    set /a CHD_FIXABLE+=1
    if /I "%ACTION%"=="FIX" call :FixOneCHD "%CHD_FILE%" "%DETECT_TYPE%" "%EXPECTED_COMP%"
)
exit /b 0

:DetectCHD
set "CHD_FILE=%~1"
set "DETECT_TYPE=UNKNOWN"
set "DETECT_COMP=STANDARD"
set "INFOFILE=%TEMP%\chd_info_%RANDOM%_%RANDOM%.txt"

"%CHDMAN%" info -v -i "%CHD_FILE%" >"%INFOFILE%" 2>&1
if errorlevel 1 (
    set "DETECT_TYPE=UNKNOWN"
    set "DETECT_COMP=UNKNOWN"
    echo [INFO FAILED] "%CHD_FILE%">>"%LOG%"
    if exist "%INFOFILE%" del /f /q "%INFOFILE%" >nul 2>nul
    exit /b 1
)

findstr /I /C:"zstd" "%INFOFILE%" >nul 2>nul
if not errorlevel 1 set "DETECT_COMP=ZSTD"

rem CD CHDs made with createcd normally contain CD track metadata tags.
findstr /I /C:"Tag='CHT" /C:"Tag=\"CHT" /C:"Tag='CHT2" /C:"TRACK" /C:"CD-ROM" /C:"CDROM" "%INFOFILE%" >nul 2>nul
if not errorlevel 1 set "DETECT_TYPE=CD"

rem DVD CHDs made with createdvd normally contain DVD metadata tags.
findstr /I /C:"Tag='DVD" /C:"Tag=\"DVD" /C:"DVD Metadata" /C:"DVD:" "%INFOFILE%" >nul 2>nul
if not errorlevel 1 set "DETECT_TYPE=DVD"

if exist "%INFOFILE%" del /f /q "%INFOFILE%" >nul 2>nul
exit /b 0

:FixOneCHD
set "CHD_FILE=%~1"
set "DETECT_TYPE=%~2"
set "TARGET_COMP=%~3"
set "TMPDIR=%~dpn1__chd_fix_tmp"
set "FIXED=%~dpn1.fixed.chd"
set "BACKUP=%~dpn1.backup_%RANDOM%.chd"

echo.
echo [FIX] %DETECT_TYPE% -> %TARGET_COMP%
echo Input:  %CHD_FILE%
echo Fixed:  %FIXED%
echo Backup: %BACKUP%
echo [FIX] Type=%DETECT_TYPE% Target=%TARGET_COMP% Input="%CHD_FILE%" Fixed="%FIXED%" Backup="%BACKUP%">>"%LOG%"

if exist "%TMPDIR%" rmdir /s /q "%TMPDIR%" >nul 2>nul
mkdir "%TMPDIR%" >nul 2>nul
if exist "%FIXED%" del /f /q "%FIXED%" >nul 2>nul

if /I "%DETECT_TYPE%"=="CD" goto FixCD
if /I "%DETECT_TYPE%"=="DVD" goto FixDVD

echo [FIX SKIP] Unknown CHD type: "%CHD_FILE%"
echo [FIX SKIP] Unknown CHD type: "%CHD_FILE%">>"%LOG%"
set /a CHD_FIX_FAILED+=1
goto FixCleanup

:FixCD
"%CHDMAN%" extractcd -i "%CHD_FILE%" -o "%TMPDIR%\source.cue"
if errorlevel 1 goto FixFailed

if /I "%TARGET_COMP%"=="ZSTD" (
    "%CHDMAN%" createcd -i "%TMPDIR%\source.cue" -o "%FIXED%" -c zstd,flac
) else (
    "%CHDMAN%" createcd -i "%TMPDIR%\source.cue" -o "%FIXED%"
)
if errorlevel 1 goto FixFailed
goto FixReplace

:FixDVD
"%CHDMAN%" extractdvd -i "%CHD_FILE%" -o "%TMPDIR%\source.iso"
if errorlevel 1 goto FixFailed

if /I "%TARGET_COMP%"=="ZSTD" (
    "%CHDMAN%" createdvd -i "%TMPDIR%\source.iso" -o "%FIXED%" -c zstd
) else (
    "%CHDMAN%" createdvd -i "%TMPDIR%\source.iso" -o "%FIXED%"
)
if errorlevel 1 goto FixFailed
goto FixReplace

:FixReplace
if not exist "%FIXED%" goto FixFailed
move "%CHD_FILE%" "%BACKUP%" >nul
if errorlevel 1 goto FixFailed
move "%FIXED%" "%CHD_FILE%" >nul
if errorlevel 1 (
    echo [FIX FAILED] Could not replace original. Attempting restore...
    echo [FIX FAILED] Could not replace original. Attempting restore...>>"%LOG%"
    if exist "%BACKUP%" move "%BACKUP%" "%CHD_FILE%" >nul 2>nul
    goto FixFailed
)

set /a CHD_FIXED+=1
echo [FIX OK] "%CHD_FILE%"
echo [FIX OK] "%CHD_FILE%" Backup="%BACKUP%">>"%LOG%"
goto FixCleanup

:FixFailed
set /a CHD_FIX_FAILED+=1
echo [FIX FAILED] "%CHD_FILE%"
echo [FIX FAILED] "%CHD_FILE%">>"%LOG%"
if exist "%FIXED%" del /f /q "%FIXED%" >nul 2>nul

:FixCleanup
if exist "%TMPDIR%" rmdir /s /q "%TMPDIR%" >nul 2>nul
exit /b 0

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
