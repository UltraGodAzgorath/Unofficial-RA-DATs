ECHO OFF
CLS
:MENU
ECHO.
ECHO =================================================================================
ECHO				  	CHDMAN OPTIONS
ECHO =================================================================================
ECHO.
ECHO		A - Convert BIN+CUE and/or ISO to CD CHD	(For PS1 and earlier roms, excluding Dreamcast roms.)
ECHO		B - Convert BIN+CUE and/or GDI to CD CHD	(For Dreamcast roms only.)
ECHO		C - Convert BIN+CUE and/or ISO to DVD CHD	(For PS2 roms only.)
ECHO		D - Convert ISO to CHD				(For PSP roms only.)
ECHO.
ECHO		J - Convert CHD to BIN+CUE		 	(For PS1 and earlier roms.)
ECHO		K - Convert CHD to GDI			 	(For Dreamcast roms only.)
ECHO		L - Convert CHD to CD ISO		 	(For CD PS2* roms.)
ECHO		M - Convert CHD to DVD ISO		 	(For PSP and DVD PS2* roms.)
ECHO.
ECHO		*The majority of PS2 games are DVD-based, a few games are CD-based
ECHO.
ECHO		R - Convert CD CHD to DVD CHD	(if an old CD CHD should be a DVD CHD)
ECHO		S - Convert PSP CD CHD to PSP DVD CHD	(if an old PSP CD CHD should be a PSP DVD CHD)
ECHO.
ECHO		Z - EXIT
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		1) Some EU PS1 games have extra .sbi protection files. Keep these files together!
ECHO		2) 3DO and Jaguar game CD's need to be kept in .cdi format
ECHO		3) This program has been tested on chdman.exe from MAME 0.272
ECHO.
ECHO =================================================================================
ECHO.
CHOICE /N /C:ABCDJKLMRSZ /M "Choose the desired option from above menu: "%1
IF ERRORLEVEL 1 SET M=A
IF ERRORLEVEL 2 SET M=B
IF ERRORLEVEL 3 SET M=C
IF ERRORLEVEL 4 SET M=D
IF ERRORLEVEL 5 SET M=J
IF ERRORLEVEL 6 SET M=K
IF ERRORLEVEL 7 SET M=L
IF ERRORLEVEL 8 SET M=M
IF ERRORLEVEL 9 SET M=R
IF ERRORLEVEL 10 SET M=S
IF ERRORLEVEL 11 SET M=Z
IF %M%==A GOTO CompressCD
IF %M%==B GOTO CompressGDI
IF %M%==C GOTO CompressDVD
IF %M%==D GOTO CompressDVD-PSP
IF %M%==J GOTO ExtractBIN
IF %M%==K GOTO ExtractGDI
IF %M%==L GOTO ExtractCDISO
IF %M%==M GOTO ExtractDVDISO
IF %M%==R GOTO ConvertCHD
IF %M%==S GOTO ConvertCHD-PSP
IF %M%==Z EXIT

:CompressCD
for /r %%i in (*.cue, *.iso) do chdman createcd -i "%%i" -o "%%~ni.chd" -c zstd
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input BIN files:
dir /A:-D /B *.bin 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input ISO files:
dir /A:-D /B *.iso 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
CALL :SUB_DelBINCUE
GOTO MENU

:CompressGDI
for /r %%i in (*.cue, *.gdi) do chdman createcd -i "%%i" -o "%%~ni.chd" -c zstd
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input CUE files:
dir /A:-D /B *.cue 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Input GDI files:
dir /A:-D /B *.gdi 2>nul | find /c /v ""
ECHO ---------------------------------------------------------------------------------
ECHO Number of Output CHD files:
dir /A:-D /B *.chd 2>nul | find /c /v ""
CALL :SUB_DelGDI
GOTO MENU

:CompressDVD
for /r %%i in (*.iso) do chdman createdvd -i "%%i" -o "%%~ni.chd" -c zstd
for /r %%i in (*.cue) do chdman createcd -i "%%i" -o "%%~ni.chd" -c zstd
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

:CompressDVD-PSP
for /r %%i in (*.iso) do chdman createdvd -hs 2048 -i "%%i" -o "%%~ni.chd" -c zstd
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

:ConvertCHD
for /r %%i in (*.chd) do chdman extractcd -i "%%i" -o "%%~ni.cue" -ob "%%~ni.iso"
Del *.cue
for /r %%i in (*.iso) do chdman createdvd -i "%%i" -o "%%~ni.chd" -c zstd
Del *.iso
GOTO MENU

:ConvertCHD-PSP
for /r %%i in (*.chd) do chdman extractcd -i "%%i" -o "%%~ni.cue" -ob "%%~ni.iso"
Del *.cue
for /r %%i in (*.iso) do chdman createdvd -hs 2048 -i "%%i" -o "%%~ni.chd" -c zstd
Del *.iso
GOTO MENU

:SUB_DelBINCUE
ECHO _________________________________________________________________________________
ECHO.
ECHO				 	DELETE OPTIONS
ECHO _________________________________________________________________________________
ECHO.
ECHO			1 - Delete Input BIN+CUE and/or ISO File(s)
ECHO			2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		should exit this program and check the files manually before
ECHO		deleting anything. An example is CHDMAN failing to process a file 
ECHO		because of non-standard characters in the input file name
ECHO _________________________________________________________________________________
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
ECHO _________________________________________________________________________________
ECHO.
ECHO				 	DELETE OPTIONS
ECHO _________________________________________________________________________________
ECHO.
ECHO			1 - Delete Input BIN+CUE and/or GDI+BIN+RAW File(s)
ECHO			2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		should exit this program and check the files manually before
ECHO		deleting anything. An example is CHDMAN failing to process a file 
ECHO		because of non-standard characters in the input file name
ECHO _________________________________________________________________________________
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
ECHO _________________________________________________________________________________
ECHO.
ECHO				 	DELETE OPTIONS
ECHO _________________________________________________________________________________
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
ECHO _________________________________________________________________________________
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
ECHO _________________________________________________________________________________
ECHO.
ECHO				  	DELETE OPTIONS
ECHO _________________________________________________________________________________
ECHO.
ECHO				1 - Delete Input CHD File(s)
ECHO				2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		should exit this program and check the files manually before
ECHO		deleting anything. An example is CHDMAN failing to process a file 
ECHO		because of non-standard characters in the input file name
ECHO _________________________________________________________________________________
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
ECHO _________________________________________________________________________________
ECHO.
ECHO				  	DELETE OPTIONS
ECHO _________________________________________________________________________________
ECHO.
ECHO				1 - Delete Input CHD File(s)
ECHO				2 - Return to Main Menu
ECHO.
ECHO		Notes: 
ECHO.		
ECHO		If the Input vs. Output file numbers above don't match, then you
ECHO		may have mixed CD and DVD CHD files. DO NOT delete the input files,
ECHO		Return to main menu and re-run with the other Extract ISO option and 
ECHO		re-check the Input vs. Output file numbers before deleting any CHD's
ECHO _________________________________________________________________________________
ECHO.
CHOICE /N /C:12 /M "Choose 1 or 2"%1
IF ERRORLEVEL 1 SET M=1
IF ERRORLEVEL 2 SET M=2
IF %M%==1 GOTO DelCHDISO
IF %M%==2 EXIT /B
:DelCHDISO
Del *.chd
CALL :MENU