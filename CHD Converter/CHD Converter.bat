ECHO OFF
CLS
:MENU
ECHO.
ECHO ======================================================================================================================
ECHO				  	CHDMAN OPTIONS
ECHO ======================================================================================================================
ECHO.
ECHO		A - Compress CD to Standard CHD		(cdlz,cdzl,cdfl)
ECHO		B - Compress CD to ZSTD CHD		(cdzs,cdzl,cdfl)
ECHO		C - Compress DVD to Standard CHD	(lzma,zlib,huff,flac)
ECHO		D - Compress DVD to ZSTD CHD		(zstd,zlib,huff,flac)
ECHO.
ECHO		E - Extract CHD to CD BIN+CUE		(For PS1 and earlier)
ECHO		F - Extract CHD to GDI			(For Dreamcast)
ECHO		G - Extract CHD to CD ISO		(For PS2 CDs)
ECHO		H - Extract CHD to DVD ISO		(For PS2 DVDs and PSP)
ECHO.
ECHO		I - Convert Standard CD CHD to ZSTD CHD
ECHO		J - Convert Standard DVD CHD to ZSTD CHD
ECHO.
ECHO		Z - EXIT
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		i)	Some EU PS1 games have extra .sbi protection files. Keep these files together!
ECHO		ii)	Jaguar CD roms need to be kept in CDI or BIN+CUE format.
ECHO		iii)	If 3DO roms are in CDI format, keep them in that format.
ECHO		iv)	This program has been tested on chdman.exe from MAME 0.272 up to 0.280.
ECHO.
ECHO ======================================================================================================================
ECHO.
CHOICE /N /C:ABCDEFGHIJZ /M "Choose the desired option from above menu: "%1
IF ERRORLEVEL 1 SET M=A
IF ERRORLEVEL 2 SET M=B
IF ERRORLEVEL 3 SET M=C
IF ERRORLEVEL 4 SET M=D
IF ERRORLEVEL 5 SET M=E
IF ERRORLEVEL 6 SET M=F
IF ERRORLEVEL 7 SET M=G
IF ERRORLEVEL 8 SET M=H
IF ERRORLEVEL 9 SET M=I
IF ERRORLEVEL 10 SET M=J
IF ERRORLEVEL 11 SET M=Z
IF %M%==A GOTO CompressCD
IF %M%==B GOTO Warning
IF %M%==C GOTO CompressDVD
IF %M%==D GOTO CompressDVDZ
IF %M%==E GOTO ExtractBIN
IF %M%==F GOTO ExtractGDI
IF %M%==G GOTO ExtractCDISO
IF %M%==H GOTO ExtractDVDISO
IF %M%==I GOTO Warning
IF %M%==J GOTO ConvertDVDCHD
IF %M%==Z EXIT

:Warning
ECHO.
ECHO ======================================================================================================================
ECHO				 	WARNING!!!
ECHO ======================================================================================================================
ECHO.
ECHO		Do not convert these CD platforms to ZSTD CHD due to no ZSTD support/compatibility:
ECHO.
ECHO			i) 	3DO Interactive Multiplayer
ECHO			ii) 	NEC PC-FX
ECHO			iii) 	NEC TurboGrafx-CD*
ECHO.
ECHO		* The Beetle PCE and Beetle PCE Fast cores support ZSTD but can't run
ECHO		SuperGrafx roms, while the Beetle SuperGrafx core can run SuperGrafx
ECHO		roms but doesn't have ZSTD support/compatibility.
ECHO.
ECHO		Do you still want to convert this platform to ZSTD CHD?
ECHO.
ECHO			1 - Yes, Compress CD to ZSTD CHD
ECHO			2 - Yes, Convert Standard CD CHD to ZSTD CHD
ECHO			3 - No (Go back to Main Menu)
ECHO.
ECHO ======================================================================================================================
ECHO.
CHOICE /N /C:123 /M "Choose the desired option from above menu: "%1
IF ERRORLEVEL 1 SET M=1
IF ERRORLEVEL 1 SET M=2
IF ERRORLEVEL 3 SET M=3
IF %M%==1 GOTO CompressCDZ
IF %M%==2 GOTO ConvertCDCHD
IF %M%==3 GOTO MENU

:CompressCD
for /r %%i in (*.cue, *.gdi, *.iso) do chdman createcd -i "%%i" -o "%%~ni.chd"
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input BIN files:
dir /A:-D /B *.bin 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input ISO files:
dir /A:-D /B *.iso 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input RAW files:
dir /A:-D /B *.raw 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
CALL :SUB_DelBINCUE
GOTO MENU

:CompressCDZ
for /r %%i in (*.cue, *.gdi, *.iso) do chdman createcd -i "%%i" -o "%%~ni.chd" -c cdzs,cdzl,cdfl
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input BIN files:
dir /A:-D /B *.bin 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input ISO files:
dir /A:-D /B *.iso 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input RAW files:
dir /A:-D /B *.raw 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
CALL :SUB_DelBINCUE
GOTO MENU

:CompressDVD
for /r %%i in (*.cue) do chdman createcd -i "%%i" -o "%%~ni.chd"
for /r %%i in (*.iso) do chdman createdvd -i "%%i" -o "%%~ni.chd"
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input BIN files:
dir /A:-D /B *.bin 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input ISO files:
dir /A:-D /B *.iso 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
CALL :SUB_DelISO
GOTO MENU

:CompressDVDZ
for /r %%i in (*.cue) do chdman createcd -i "%%i" -o "%%~ni.chd" -c cdzs,cdzl,cdfl
for /r %%i in (*.iso) do chdman createdvd -i "%%i" -o "%%~ni.chd" -c zstd,zlib,huff,flac
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input BIN files:
dir /A:-D /B *.bin 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input ISO files:
dir /A:-D /B *.iso 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
CALL :SUB_DelISO
GOTO MENU

:ExtractBIN
for /r %%i in (*.chd) do chdman extractcd -i "%%i" -o "%%~ni.cue" -ob "%%~ni.bin"
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output BIN files:
dir /A:-D /B *.bin 2>nul | find /c /v ""
CALL :SUB_DelCHD
GOTO MENU

:ExtractGDI
for /r %%i in (*.chd) do chdman extractcd -i "%%i" -o "%%~ni.gdi"
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output GDI files:
dir /A:-D /B *.gdi 2>nul | find /c /v ""
CALL :SUB_DelCHD
GOTO MENU

:ExtractCDISO
for /r %%i in (*.chd) do chdman extractcd -i "%%i" -o "%%~ni.cue" -ob "%%~ni.iso"
Del *.cue
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output ISO files:
dir /A:-D /B *.iso 2>nul | find /c /v ""
CALL :SUB_DelCHDISO
GOTO MENU

:ExtractDVDISO
for /r %%i in (*.chd) do chdman extractdvd -i "%%i" -o "%%~ni.iso"
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output ISO files:
dir /A:-D /B *.iso 2>nul | find /c /v ""
CALL :SUB_DelCHDISO
GOTO MENU

:ConvertCDCHD
for /r %%i in (*.chd) do chdman extractcd -i "%%i" -o "%%~ni.cue" -ob "%%~ni.bin"
Del *.CHD
for /r %%i in (*.cue) do chdman createcd -i "%%i" -o "%%~ni.chd" -c cdzs,cdzl,cdfl
Del *.CUE
Del *.BIN
GOTO MENU

:ConvertDVDCHD
for /r %%i in (*.chd) do chdman extractdvd -i "%%i" -o "%%~ni.iso"
Del *.CHD
for /r %%i in (*.iso) do chdman createdvd -i "%%i" -o "%%~ni.chd" -c zstd,zlib,huff,flac
Del *.ISO
GOTO MENU

:SUB_DelBINCUE
ECHO ======================================================================================================================
ECHO				 	DELETE OPTIONS
ECHO ======================================================================================================================
ECHO.
ECHO			1 - Delete Input BIN+CUE and/or ISO File(s)
ECHO			2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		should exit this program and check the files manually before
ECHO		deleting anything. An example is CHDMAN failing to process a file 
ECHO		because of non-standard characters in the input file name.
ECHO.
ECHO ======================================================================================================================
ECHO.
CHOICE /N /C:12 /M "Choose 1 or 2"%1
IF ERRORLEVEL 1 SET M=1
IF ERRORLEVEL 2 SET M=2
IF %M%==1 GOTO DelBINCUE
IF %M%==2 EXIT /B
:DelBINCUE
Del *.iso
Del *.bin
Del *.cue
CALL :MENU

:SUB_DelGDI
ECHO ======================================================================================================================
ECHO				 	DELETE OPTIONS
ECHO ======================================================================================================================
ECHO.
ECHO			1 - Delete Input BIN+CUE and/or GDI+BIN+RAW File(s)
ECHO			2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		should exit this program and check the files manually before
ECHO		deleting anything. An example is CHDMAN failing to process a file 
ECHO		because of non-standard characters in the input file name.
ECHO.
ECHO ======================================================================================================================
ECHO.
CHOICE /N /C:12 /M "Choose 1 or 2"%1
IF ERRORLEVEL 1 SET M=1
IF ERRORLEVEL 2 SET M=2
IF %M%==1 GOTO DelGDI
IF %M%==2 EXIT /B
:DelGDI
Del *.gdi
Del *.bin
Del *.raw
CALL :MENU

:SUB_DelISO
ECHO ======================================================================================================================
ECHO				 	DELETE OPTIONS
ECHO ======================================================================================================================
ECHO.
ECHO				1 - Delete Input ISO File(s)
ECHO				2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		should exit this program and check the files manually before
ECHO		deleting anything. An example is CHDMAN failing to process a file 
ECHO		because of non-standard characters in the input file name
ECHO.
ECHO ======================================================================================================================
ECHO.
CHOICE /N /C:12 /M "Choose 1 or 2"%1
IF ERRORLEVEL 1 SET M=1
IF ERRORLEVEL 2 SET M=2
IF %M%==1 GOTO DelISO
IF %M%==2 EXIT /B
:DelISO
Del *.iso
CALL :MENU


:SUB_DelCHD
ECHO ======================================================================================================================
ECHO				  	DELETE OPTIONS
ECHO ======================================================================================================================
ECHO.
ECHO				1 - Delete Input CHD File(s)
ECHO				2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		should exit this program and check the files manually before
ECHO		deleting anything. An example is CHDMAN failing to process a file 
ECHO		because of non-standard characters in the input file name.
ECHO.
ECHO ======================================================================================================================
ECHO.
CHOICE /N /C:12 /M "Choose 1 or 2"%1
IF ERRORLEVEL 1 SET M=1
IF ERRORLEVEL 2 SET M=2
IF %M%==1 GOTO DelCHD
IF %M%==2 EXIT /B
:DelCHD
Del *.chd
CALL :MENU

:SUB_DelCHDISO
ECHO ======================================================================================================================
ECHO				  	DELETE OPTIONS
ECHO ======================================================================================================================
ECHO.
ECHO				1 - Delete Input CHD File(s)
ECHO				2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		may have mixed CD and DVD CHD files. DO NOT delete the input files,
ECHO		Return to main menu and re-run with the other Extract ISO option and 
ECHO		re-check the Input vs. Output file numbers before deleting any CHD's.
ECHO.
ECHO ======================================================================================================================
ECHO.
CHOICE /N /C:12 /M "Choose 1 or 2"%1
IF ERRORLEVEL 1 SET M=1
IF ERRORLEVEL 2 SET M=2
IF %M%==1 GOTO DelCHDISO
IF %M%==2 EXIT /B
:DelCHDISO
Del *.chd
CALL :MENU