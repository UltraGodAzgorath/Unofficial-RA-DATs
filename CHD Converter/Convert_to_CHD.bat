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
rem - CD ZSTD uses cdzs,cdzl,cdfl. DVD ZSTD uses zstd,zlib,huff,flac.
rem - PS2 uses one folder: .cue = createcd ZSTD, .iso = createdvd ZSTD.
rem - Loose .bin files are ignored. Use the matching .cue file.
rem
rem Added checker/fixer:
rem - Uses chdman info -v to inspect existing CHD metadata.
rem - Detects CD CHD vs DVD CHD when metadata is available.
rem - Detects ZSTD vs standard/default compression, including CD codec cdzs.
rem - Can fix wrong compression by extracting to temp files and recompressing.
rem - Original CHDs are renamed to .backup_RANDOM.chd after a successful fix.
rem - CHD check/fix uses environment variables plus PowerShell for chdman calls,
rem   so legal filename characters like %, ^, &, and ! do not need renaming.
rem - Path display lines are quoted so names containing & are not parsed as commands.
rem
rem Added cleanup/convenience options:
rem - Convert one selected system folder instead of all folders.
rem - Fix wrong CHD compression for all folders or one selected folder.
rem - Optionally move successfully converted source files to _Converted_Source,
rem   or delete successfully converted source files after confirmation.
rem ============================================================

set "ROOT=%~dp0"
set "CHDMAN=%ROOT%chdman.exe"
set "LOGDIR=%ROOT%_Logs"
set "LOG=%LOGDIR%\CHD_Converter.log"
set "MOVE_ORIGINALS=NO"
set "NONINTERACTIVE=NO"

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

if /I "%~1"=="/AUTO" set "NONINTERACTIVE=YES" & goto ConvertAll
if /I "%~1"=="/RUN" set "NONINTERACTIVE=YES" & goto ConvertAll
if /I "%~1"=="/CHECK" goto CheckCHDs
if /I "%~1"=="/FIX" goto FixCHDs

:MainMenu
set "SELECTED_SYSTEM="
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
echo 2 - Convert one selected system folder to CHD
echo 3 - Check existing CHD format/compression
echo 4 - Fix wrong CHD compression for all systems
echo 5 - Fix wrong CHD compression for one selected system
echo 6 - Show folder/method list
echo 7 - Verify chdman.exe
echo 8 - Exit
echo.
choice /C 12345678 /N /M "Choose an option: "
if errorlevel 8 goto End
if errorlevel 7 goto VerifyCHDMan
if errorlevel 6 goto ShowMethods
if errorlevel 5 goto FixOneSystemMenu
if errorlevel 4 goto FixCHDs
if errorlevel 3 goto CheckCHDs
if errorlevel 2 goto ConvertOneSystemMenu
if errorlevel 1 goto ConvertAll

goto MainMenu


:ConvertOneSystemMenu
cls
echo ============================================================
echo Convert One System Folder
echo ============================================================
echo.
call :PrintSystemMenu
call :ReadInstantSystemChoice "Choose a system: "
call :ResolveSystemChoice
if not defined SELECTED_SYSTEM goto MainMenu
goto ConvertSelectedSystem

:FixOneSystemMenu
cls
echo ============================================================
echo Fix Wrong CHD Compression - One System Folder
echo ============================================================
echo.
call :PrintSystemMenu
call :ReadInstantSystemChoice "Choose a system to fix: "
call :ResolveSystemChoice
if not defined SELECTED_SYSTEM goto MainMenu
goto FixSelectedSystem

:PrintSystemMenu
echo 1 - 3DO Interactive Multiplayer
echo 2 - NEC PC-FX
echo 3 - NEC TurboGrafx-CD
echo 4 - Sega CD
echo 5 - Sega Dreamcast
echo 6 - Sega Saturn
echo 7 - SNK Neo Geo CD
echo 8 - Sony PlayStation
echo 9 - Sony PlayStation 2
echo 0 - Sony PlayStation Portable
echo B - Back
echo.
exit /b 0

:ReadInstantSystemChoice
set "SYS_CHOICE="
<nul set /p "=%~1"
for /f "usebackq delims=" %%K in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').Character" 2^>nul`) do set "SYS_CHOICE=%%K"
echo.
if not defined SYS_CHOICE (
    set /P "SYS_CHOICE=%~1"
)
exit /b 0

:ResolveSystemChoice
set "SELECTED_SYSTEM="
if /I "%SYS_CHOICE%"=="B" exit /b 0
if "%SYS_CHOICE%"=="1" set "SELECTED_SYSTEM=3DO Interactive Multiplayer"
if "%SYS_CHOICE%"=="2" set "SELECTED_SYSTEM=NEC PC-FX"
if "%SYS_CHOICE%"=="3" set "SELECTED_SYSTEM=NEC TurboGrafx-CD"
if "%SYS_CHOICE%"=="4" set "SELECTED_SYSTEM=Sega CD"
if "%SYS_CHOICE%"=="5" set "SELECTED_SYSTEM=Sega Dreamcast"
if "%SYS_CHOICE%"=="6" set "SELECTED_SYSTEM=Sega Saturn"
if "%SYS_CHOICE%"=="7" set "SELECTED_SYSTEM=SNK Neo Geo CD"
if "%SYS_CHOICE%"=="8" set "SELECTED_SYSTEM=Sony PlayStation"
if "%SYS_CHOICE%"=="9" set "SELECTED_SYSTEM=Sony PlayStation 2"
if "%SYS_CHOICE%"=="0" set "SELECTED_SYSTEM=Sony PlayStation Portable"
exit /b 0

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
echo ZSTD createcd -c cdzs,cdzl,cdfl:
echo   Sega CD                         *.cue
echo   Sega Dreamcast                  *.gdi, *.cue
echo   Sega Saturn                     *.cue
echo   SNK Neo Geo CD                  *.cue
echo   Sony PlayStation                *.cue
echo   Sony PlayStation 2              *.cue
echo.
echo ZSTD createdvd -c zstd,zlib,huff,flac:
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
echo   - Source files are never deleted.
echo   - Optional cleanup can move successfully converted source files to _Converted_Source.
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

call :ConfigureMoveOriginals

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
echo Source cleanup after success: %MOVE_ORIGINALS%>>"%LOG%"
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
call :ProcessCDDefaultSafe "3DO Interactive Multiplayer" "*.cue"
call :ProcessCDDefaultSafe "3DO Interactive Multiplayer" "*.iso"
call :ProcessCDDefaultSafe "NEC PC-FX" "*.cue"
call :ProcessCDDefaultSafe "NEC TurboGrafx-CD" "*.cue"

rem ZSTD CD CHDs.
call :ProcessCDZstdSafe "Sega CD" "*.cue"
call :ProcessCDZstdSafe "Sega Dreamcast" "*.gdi"
call :ProcessCDZstdSafe "Sega Dreamcast" "*.cue"
call :ProcessCDZstdSafe "Sega Saturn" "*.cue"
call :ProcessCDZstdSafe "SNK Neo Geo CD" "*.cue"
call :ProcessCDZstdSafe "Sony PlayStation" "*.cue"
call :ProcessCDZstdSafe "Sony PlayStation 2" "*.cue"

rem ZSTD DVD CHDs.
call :ProcessDVDZstdSafe "Sony PlayStation 2" "*.iso"
call :ProcessDVDZstdSafe "Sony PlayStation Portable" "*.iso"

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


:ConfigureMoveOriginals
set "MOVE_ORIGINALS=NO"
if /I "%NONINTERACTIVE%"=="YES" exit /b 0
echo.
echo Cleanup option after successful conversion:
echo.
echo   K - Keep source files where they are
echo   M - Move source files to:
echo       %ROOT%_Converted_Source
echo   D - Delete source files permanently
echo.
echo For CUE/GDI sets, the BAT will try to process referenced BIN/RAW files too.
echo PS1 SBI files are left beside the CHD because some games need them for play.
echo Delete only runs after a CHD was created successfully.
echo.
choice /C KMD /N /M "After successful conversion: [K]eep, [M]ove, or [D]elete source files? "
if errorlevel 3 goto ConfigureDeleteOriginals
if errorlevel 2 goto ConfigureMoveOriginalsYes
set "MOVE_ORIGINALS=NO"
goto ConfigureMoveOriginalsDone

:ConfigureMoveOriginalsYes
set "MOVE_ORIGINALS=YES"
if not exist "%ROOT%_Converted_Source" mkdir "%ROOT%_Converted_Source" >nul 2>nul
goto ConfigureMoveOriginalsDone

:ConfigureDeleteOriginals
set "MOVE_ORIGINALS=DELETE"
echo.
echo WARNING: This will permanently delete source ROM files after successful conversion.
echo For CUE/GDI sets, referenced BIN/RAW files will be deleted too.
echo CHD files and PS1 SBI files will not be deleted by this cleanup option.
echo.
set "DELETE_CONFIRM="
set /P "DELETE_CONFIRM=Type DELETE to enable delete-after-success, or press Enter to keep files: "
if /I not "%DELETE_CONFIRM%"=="DELETE" set "MOVE_ORIGINALS=NO"

:ConfigureMoveOriginalsDone
echo.
echo Source cleanup after success: %MOVE_ORIGINALS%
exit /b 0

:ConvertSelectedSystem
if not defined SELECTED_SYSTEM goto MainMenu
cls
echo ============================================================
echo RetroAchievements CHD Auto Converter - Convert One System
echo ============================================================
echo.
echo Selected system:
echo %SELECTED_SYSTEM%
echo.

set /a FOUND=0
set /a CONVERTED=0
set /a SKIPPED=0
set /a FAILED=0
set /a TOTAL_FOUND=0
set /a TOTAL_TO_CONVERT=0
set /a CURRENT=0

call :ConfigureMoveOriginals

echo Scanning folder...
call :CountSystem "%SELECTED_SYSTEM%"

echo.
echo Candidates found: %TOTAL_FOUND%
echo Need conversion:  %TOTAL_TO_CONVERT%
echo.

echo.>>"%LOG%"
echo ============================================================>>"%LOG%"
echo Convert selected-system run started: %DATE% %TIME%>>"%LOG%"
echo System: %SELECTED_SYSTEM%>>"%LOG%"
echo Root: %ROOT%>>"%LOG%"
echo chdman: %CHDMAN%>>"%LOG%"
echo Candidates found: %TOTAL_FOUND%>>"%LOG%"
echo Need conversion: %TOTAL_TO_CONVERT%>>"%LOG%"
echo Source cleanup after success: %MOVE_ORIGINALS%>>"%LOG%"
echo ============================================================>>"%LOG%"

if %TOTAL_FOUND% EQU 0 (
    echo No supported source files were found for this system.
    echo.
    pause
    goto MainMenu
)

if %TOTAL_TO_CONVERT% EQU 0 (
    echo All supported source files for this system already have matching CHD files.
    echo Nothing to convert.
    echo.
    pause
    goto MainMenu
)

call :ProcessSystem "%SELECTED_SYSTEM%"

echo.>>"%LOG%"
echo Convert selected-system summary: Found=%FOUND% Converted=%CONVERTED% Skipped=%SKIPPED% Failed=%FAILED%>>"%LOG%"
echo Convert selected-system run finished: %DATE% %TIME%>>"%LOG%"

echo.
echo ============================================================
echo Done
echo ============================================================
echo System:    %SELECTED_SYSTEM%
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

:CountSystem
if /I "%~1"=="3DO Interactive Multiplayer" (
    call :CountFiles "3DO Interactive Multiplayer" "*.cue"
    call :CountFiles "3DO Interactive Multiplayer" "*.iso"
    exit /b 0
)
if /I "%~1"=="NEC PC-FX" (
    call :CountFiles "NEC PC-FX" "*.cue"
    exit /b 0
)
if /I "%~1"=="NEC TurboGrafx-CD" (
    call :CountFiles "NEC TurboGrafx-CD" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sega CD" (
    call :CountFiles "Sega CD" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sega Dreamcast" (
    call :CountFiles "Sega Dreamcast" "*.gdi"
    call :CountFiles "Sega Dreamcast" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sega Saturn" (
    call :CountFiles "Sega Saturn" "*.cue"
    exit /b 0
)
if /I "%~1"=="SNK Neo Geo CD" (
    call :CountFiles "SNK Neo Geo CD" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sony PlayStation" (
    call :CountFiles "Sony PlayStation" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sony PlayStation 2" (
    call :CountFiles "Sony PlayStation 2" "*.cue"
    call :CountFiles "Sony PlayStation 2" "*.iso"
    exit /b 0
)
if /I "%~1"=="Sony PlayStation Portable" (
    call :CountFiles "Sony PlayStation Portable" "*.iso"
    exit /b 0
)
exit /b 0

:ProcessSystem
if /I "%~1"=="3DO Interactive Multiplayer" (
    call :ProcessCDDefaultSafe "3DO Interactive Multiplayer" "*.cue"
    call :ProcessCDDefaultSafe "3DO Interactive Multiplayer" "*.iso"
    exit /b 0
)
if /I "%~1"=="NEC PC-FX" (
    call :ProcessCDDefaultSafe "NEC PC-FX" "*.cue"
    exit /b 0
)
if /I "%~1"=="NEC TurboGrafx-CD" (
    call :ProcessCDDefaultSafe "NEC TurboGrafx-CD" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sega CD" (
    call :ProcessCDZstdSafe "Sega CD" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sega Dreamcast" (
    call :ProcessCDZstdSafe "Sega Dreamcast" "*.gdi"
    call :ProcessCDZstdSafe "Sega Dreamcast" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sega Saturn" (
    call :ProcessCDZstdSafe "Sega Saturn" "*.cue"
    exit /b 0
)
if /I "%~1"=="SNK Neo Geo CD" (
    call :ProcessCDZstdSafe "SNK Neo Geo CD" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sony PlayStation" (
    call :ProcessCDZstdSafe "Sony PlayStation" "*.cue"
    exit /b 0
)
if /I "%~1"=="Sony PlayStation 2" (
    call :ProcessCDZstdSafe "Sony PlayStation 2" "*.cue"
    call :ProcessDVDZstdSafe "Sony PlayStation 2" "*.iso"
    exit /b 0
)
if /I "%~1"=="Sony PlayStation Portable" (
    call :ProcessDVDZstdSafe "Sony PlayStation Portable" "*.iso"
    exit /b 0
)
exit /b 0

:MoveSourceSet
set "MOVE_INPUT=%~1"
set "MOVE_FOLDER=%~2"
set "MOVE_EXT=%~x1"
set "MOVE_SOURCE_ROOT=%ROOT%%~2"
set "MOVE_DEST_ROOT=%ROOT%_Converted_Source\%~2"

if not exist "%MOVE_DEST_ROOT%" mkdir "%MOVE_DEST_ROOT%" >nul 2>nul

echo [MOVE] Moving source files for: "%MOVE_INPUT%"
echo [MOVE] Moving source files for: "%MOVE_INPUT%">>"%LOG%"

if /I "%MOVE_EXT%"==".cue" goto MoveCueSet
if /I "%MOVE_EXT%"==".gdi" goto MoveGdiSet

goto MoveSingleInput

:MoveCueSet
rem Move files referenced by quoted FILE lines before moving the CUE itself.
for /f tokens^=2^ delims^=^" %%R in ('findstr /I /B /C:"FILE " "%MOVE_INPUT%" 2^>nul') do call :MoveOneFile "%~dp1%%~R" "%MOVE_SOURCE_ROOT%" "%MOVE_DEST_ROOT%"
if exist "%~dpn1.sbi" (
    echo [KEEP] SBI left beside CHD: "%~dpn1.sbi"
    echo [KEEP] SBI left beside CHD: "%~dpn1.sbi">>"%LOG%"
)
goto MoveSingleInput

:MoveGdiSet
rem Common GDI format uses token 5 as the referenced track filename.
for /f "usebackq skip=1 tokens=5" %%R in ("%MOVE_INPUT%") do call :MoveOneFile "%~dp1%%~R" "%MOVE_SOURCE_ROOT%" "%MOVE_DEST_ROOT%"
goto MoveSingleInput

:MoveSingleInput
call :MoveOneFile "%MOVE_INPUT%" "%MOVE_SOURCE_ROOT%" "%MOVE_DEST_ROOT%"
exit /b 0

:MoveOneFile
setlocal EnableDelayedExpansion
set "SRC=%~1"
set "SRCROOT=%~2"
set "DESTROOT=%~3"
if not exist "!SRC!" (
    echo [MOVE WARN] Missing referenced source: "!SRC!"
    echo [MOVE WARN] Missing referenced source: "!SRC!">>"%LOG%"
    endlocal & exit /b 0
)
set "SRCDIR=%~dp1"
set "RELDIR=!SRCDIR:%~2\=!"
if "!RELDIR!"=="!SRCDIR!" set "RELDIR="
set "DESTDIR=!DESTROOT!\!RELDIR!"
if not exist "!DESTDIR!" mkdir "!DESTDIR!" >nul 2>nul
if exist "!DESTDIR!\%~nx1" (
    echo [MOVE SKIP] Destination already exists: "!DESTDIR!\%~nx1"
    echo [MOVE SKIP] Destination already exists: "!DESTDIR!\%~nx1">>"%LOG%"
    endlocal & exit /b 0
)
move "!SRC!" "!DESTDIR!\" >nul
if errorlevel 1 (
    echo [MOVE FAILED] "!SRC!"
    echo [MOVE FAILED] "!SRC!">>"%LOG%"
) else (
    echo [MOVED] "!SRC!" -^> "!DESTDIR!\"
    echo [MOVED] "!SRC!" -^> "!DESTDIR!\">>"%LOG%"
)
endlocal & exit /b 0

:DeleteSourceSet
if not defined CLEANUP_INPUT exit /b 0
echo [DELETE] Deleting source files for: "%CLEANUP_INPUT%"
echo [DELETE] Deleting source files for: "%CLEANUP_INPUT%">>"%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; $inputPath=$env:CLEANUP_INPUT; $log=$env:LOG; $dir=[IO.Path]::GetDirectoryName($inputPath); $ext=[IO.Path]::GetExtension($inputPath).ToLowerInvariant(); $paths=New-Object 'System.Collections.Generic.List[string]'; $paths.Add($inputPath); if($ext -eq '.cue' -and [IO.File]::Exists($inputPath)){ foreach($line in [IO.File]::ReadLines($inputPath)){ $m=[regex]::Match($line, '^\s*FILE\s+\x22([^\x22]+)\x22', 'IgnoreCase'); if($m.Success){ $paths.Add([IO.Path]::Combine($dir,$m.Groups[1].Value)) } }; $sbi=[IO.Path]::ChangeExtension($inputPath,'.sbi'); if([IO.File]::Exists($sbi)){ Write-Host ('[KEEP] SBI left beside CHD: ' + $sbi); Add-Content -LiteralPath $log -Value ('[KEEP] SBI left beside CHD: ' + $sbi) } } elseif($ext -eq '.gdi' -and [IO.File]::Exists($inputPath)){ $lines=[IO.File]::ReadAllLines($inputPath); for($i=1; $i -lt $lines.Count; $i++){ $parts=$lines[$i] -split '\s+'; if($parts.Count -ge 5){ $paths.Add([IO.Path]::Combine($dir,$parts[4])) } } }; $seen=@{}; foreach($p in $paths){ if([string]::IsNullOrWhiteSpace($p)){ continue }; $full=[IO.Path]::GetFullPath($p); if($seen.ContainsKey($full)){ continue }; $seen[$full]=$true; if([IO.File]::Exists($full)){ try{ Remove-Item -LiteralPath $full -Force -ErrorAction Stop; Write-Host ('[DELETED] ' + $full); Add-Content -LiteralPath $log -Value ('[DELETED] ' + $full) } catch { Write-Host ('[DELETE FAILED] ' + $full + ' :: ' + $_.Exception.Message); Add-Content -LiteralPath $log -Value ('[DELETE FAILED] ' + $full + ' :: ' + $_.Exception.Message) } } else { Write-Host ('[DELETE WARN] Missing referenced source: ' + $full); Add-Content -LiteralPath $log -Value ('[DELETE WARN] Missing referenced source: ' + $full) } }"
exit /b 0

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
for /r "%SYSTEMDIR%" %%F in (%PATTERN%) do call :ConvertOne CD_DEFAULT "%FOLDER%" "%%~fF"
exit /b 0

:ProcessCDZstd
set "FOLDER=%~1"
set "PATTERN=%~2"
set "SYSTEMDIR=%ROOT%%~1"
if not exist "%SYSTEMDIR%" exit /b 0

echo.
echo [CD ZSTD] %FOLDER% - %PATTERN%
echo [CD ZSTD] %FOLDER% - %PATTERN%>>"%LOG%"
for /r "%SYSTEMDIR%" %%F in (%PATTERN%) do call :ConvertOne CD_ZSTD "%FOLDER%" "%%~fF"
exit /b 0

:ProcessDVDZstd
set "FOLDER=%~1"
set "PATTERN=%~2"
set "SYSTEMDIR=%ROOT%%~1"
if not exist "%SYSTEMDIR%" exit /b 0

echo.
echo [DVD ZSTD] %FOLDER% - %PATTERN%
echo [DVD ZSTD] %FOLDER% - %PATTERN%>>"%LOG%"
for /r "%SYSTEMDIR%" %%F in (%PATTERN%) do call :ConvertOne DVD_ZSTD "%FOLDER%" "%%~fF"
exit /b 0

:ConvertOne
set "MODE=%~1"
set "CURRENT_FOLDER=%~2"
set "INPUT=%~3"
set "OUTPUT=%~dpn3.chd"

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
echo Input:    "%INPUT%"
echo Output:   "%OUTPUT%"
echo [CONVERT] Mode=%MODE% Input="%INPUT%" Output="%OUTPUT%">>"%LOG%"

if /I "%MODE%"=="CD_DEFAULT" (
    "%CHDMAN%" createcd -i "%INPUT%" -o "%OUTPUT%"
    goto CheckConvertResult
)

if /I "%MODE%"=="CD_ZSTD" (
    "%CHDMAN%" createcd -i "%INPUT%" -o "%OUTPUT%" -c cdzs,cdzl,cdfl
    goto CheckConvertResult
)

if /I "%MODE%"=="DVD_ZSTD" (
    "%CHDMAN%" createdvd -i "%INPUT%" -o "%OUTPUT%" -c zstd,zlib,huff,flac
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
    if /I "%MOVE_ORIGINALS%"=="YES" call :MoveSourceSet "%INPUT%" "%CURRENT_FOLDER%"
    if /I "%MOVE_ORIGINALS%"=="DELETE" (
        set "CLEANUP_INPUT=%INPUT%"
        set "CLEANUP_FOLDER=%CURRENT_FOLDER%"
        call :DeleteSourceSet
    )
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

:FixSelectedSystem
if not defined SELECTED_SYSTEM goto MainMenu
cls
echo ============================================================
echo Fix Wrong CHD Compression - One System
echo ============================================================
echo.
echo Selected system:
echo %SELECTED_SYSTEM%
echo.
echo This will scan only this system folder, extract fixable wrong-compression
echo CHDs to temporary files, then recompress them with the correct compression.
echo.
echo Original CHDs are not deleted. After a successful fix, the original CHD
echo is renamed to:
echo   game.backup_RANDOM.chd
echo.
echo Unknown CHD types are skipped. Wrong disc type for the folder is skipped.
echo Make sure you have enough free disk space before continuing.
echo.
choice /C YN /N /M "Continue with fixing this system? [Y/N]: "
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
echo CHD selected-system fix started: %DATE% %TIME%>>"%LOG%"
echo System: %SELECTED_SYSTEM%>>"%LOG%"
echo ============================================================>>"%LOG%"

call :RunCHDScanForSystem "%SELECTED_SYSTEM%" FIX

echo.>>"%LOG%"
echo CHD selected-system fix summary: System=%SELECTED_SYSTEM% Checked=%CHD_CHECKED% OK=%CHD_OK% Wrong=%CHD_WRONG% Unknown=%CHD_UNKNOWN% Fixable=%CHD_FIXABLE% Fixed=%CHD_FIXED% FixFailed=%CHD_FIX_FAILED%>>"%LOG%"
echo CHD selected-system fix finished: %DATE% %TIME%>>"%LOG%"

echo.
echo ============================================================
echo Fix complete
echo ============================================================
echo System:     %SELECTED_SYSTEM%
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

:RunCHDScanForSystem
set "SCAN_SYSTEM=%~1"
set "CHECK_ACTION=%~2"
if /I "%SCAN_SYSTEM%"=="3DO Interactive Multiplayer" (
    call :ProcessCHDFolder "3DO Interactive Multiplayer" "CD" "STANDARD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="NEC PC-FX" (
    call :ProcessCHDFolder "NEC PC-FX" "CD" "STANDARD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="NEC TurboGrafx-CD" (
    call :ProcessCHDFolder "NEC TurboGrafx-CD" "CD" "STANDARD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="Sega CD" (
    call :ProcessCHDFolder "Sega CD" "CD" "ZSTD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="Sega Dreamcast" (
    call :ProcessCHDFolder "Sega Dreamcast" "CD" "ZSTD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="Sega Saturn" (
    call :ProcessCHDFolder "Sega Saturn" "CD" "ZSTD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="SNK Neo Geo CD" (
    call :ProcessCHDFolder "SNK Neo Geo CD" "CD" "ZSTD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="Sony PlayStation" (
    call :ProcessCHDFolder "Sony PlayStation" "CD" "ZSTD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="Sony PlayStation 2" (
    call :ProcessCHDFolder "Sony PlayStation 2" "ANY" "ZSTD"
    exit /b 0
)
if /I "%SCAN_SYSTEM%"=="Sony PlayStation Portable" (
    call :ProcessCHDFolder "Sony PlayStation Portable" "DVD" "ZSTD"
    exit /b 0
)
echo [FIX ERROR] Unknown system: %SCAN_SYSTEM%
echo [FIX ERROR] Unknown system: %SCAN_SYSTEM%>>"%LOG%"
exit /b 1

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
for /r "%SYSTEMDIR%" %%F in (*.chd) do (
    rem Avoid passing CHD paths through CALL arguments. This protects legal
    rem filenames containing %, ^, &, !, etc.
    set "CHD_CURRENT=%%~fF"
    set "CHD_CURRENT_NAME=%%~nxF"
    call :CheckCurrentCHD "%EXPECTED_TYPE%" "%EXPECTED_COMP%" "%CHECK_ACTION%"
)
exit /b 0

:CheckCurrentCHD
rem CHD path is read from CHD_CURRENT so legal filename chars are not passed through CALL arguments.
set "CHD_FILE=%CHD_CURRENT%"
set "EXPECTED_TYPE=%~1"
set "EXPECTED_COMP=%~2"
set "ACTION=%~3"

set /a CHD_CHECKED+=1

call :DetectCHD

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
    if /I "%ACTION%"=="FIX" call :FixCurrentCHD "%DETECT_TYPE%" "%EXPECTED_COMP%"
)
exit /b 0

:DetectCHD
rem CHD_FILE is set by CheckCurrentCHD from CHD_CURRENT.
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

rem Detect compression. CD ZSTD CHDs may show cdzs instead of zstd.
findstr /I /C:"zstd" /C:"cdzs" "%INFOFILE%" >nul 2>nul
if not errorlevel 1 set "DETECT_COMP=ZSTD"

rem Detect CD/GD CHDs. Avoid fragile quoted Tag= patterns because chdman output varies.
findstr /I /C:"CHT" /C:"CHTR" /C:"CHT2" /C:"CHCD" /C:"CHGD" /C:"CHGT" /C:"TRACK" /C:"CD-ROM" /C:"CDROM" /C:"GD-ROM" /C:"GDROM" "%INFOFILE%" >nul 2>nul
if not errorlevel 1 set "DETECT_TYPE=CD"

rem Detect createdvd CHDs. Only set DVD if CD was not already detected.
if /I "%DETECT_TYPE%"=="UNKNOWN" (
    findstr /I /C:"DVD" "%INFOFILE%" >nul 2>nul
    if not errorlevel 1 set "DETECT_TYPE=DVD"
)

rem Fallback by sector/unit size. createcd CHDs usually use 2448-byte sectors; createdvd CHDs use 2048-byte sectors.
if /I "%DETECT_TYPE%"=="UNKNOWN" (
    findstr /I /C:"2448" /C:"2,448" "%INFOFILE%" >nul 2>nul
    if not errorlevel 1 set "DETECT_TYPE=CD"
)
if /I "%DETECT_TYPE%"=="UNKNOWN" (
    findstr /I /C:"2048" /C:"2,048" "%INFOFILE%" >nul 2>nul
    if not errorlevel 1 set "DETECT_TYPE=DVD"
)

rem Final safe fallback by folder rule. If the selected folder only allows one disc type,
rem classify unknown CHDs as that expected type so wrong-compression fixing can still work.
rem PS2 remains ANY and therefore still requires metadata/size detection.
if /I "%DETECT_TYPE%"=="UNKNOWN" (
    if /I "%EXPECTED_TYPE%"=="CD" set "DETECT_TYPE=CD"
)
if /I "%DETECT_TYPE%"=="UNKNOWN" (
    if /I "%EXPECTED_TYPE%"=="DVD" set "DETECT_TYPE=DVD"
)

if exist "%INFOFILE%" del /f /q "%INFOFILE%" >nul 2>nul
exit /b 0

:FixCurrentCHD
rem CHD path is read from CHD_CURRENT so legal filename chars are not passed through CALL arguments.
set "CHD_FILE=%CHD_CURRENT%"
set "DETECT_TYPE=%~1"
set "TARGET_COMP=%~2"
for %%A in ("%CHD_FILE%") do (
    set "CHD_DIR=%%~dpA"
    set "CHD_BASE=%%~nA"
)
set "TMPDIR=%TEMP%\chd_fix_%RANDOM%_%RANDOM%"
set "FIXED=%TMPDIR%\fixed.chd"
set "BACKUP=%CHD_DIR%%CHD_BASE%.backup_%RANDOM%.chd"

echo.
echo [FIX] %DETECT_TYPE% -> %TARGET_COMP%
echo Input:  "%CHD_FILE%"
echo Fixed:  "%FIXED%"
echo Backup: "%BACKUP%"
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
    "%CHDMAN%" createcd -i "%TMPDIR%\source.cue" -o "%FIXED%" -c cdzs,cdzl,cdfl
) else (
    "%CHDMAN%" createcd -i "%TMPDIR%\source.cue" -o "%FIXED%"
)
if errorlevel 1 goto FixFailed
goto FixReplace

:FixDVD
"%CHDMAN%" extractdvd -i "%CHD_FILE%" -o "%TMPDIR%\source.iso"
if errorlevel 1 goto FixFailed

if /I "%TARGET_COMP%"=="ZSTD" (
    "%CHDMAN%" createdvd -i "%TMPDIR%\source.iso" -o "%FIXED%" -c zstd,zlib,huff,flac
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


:ProcessCDDefaultSafe
call :ProcessCDDefault "%~1" "%~2"
exit /b %ERRORLEVEL%

:ProcessCDZstdSafe
call :ProcessCDZstd "%~1" "%~2"
exit /b %ERRORLEVEL%

:ProcessDVDZstdSafe
call :ProcessDVDZstd "%~1" "%~2"
exit /b %ERRORLEVEL%

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
