@ECHO OFF
REM.-- Prepare the Command Processor
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

REM.-- Version History --
REM         XX.XXX           YYYYMMDD Author Description
SET version=01.000-beta &rem 20051201 p.h.  initial version, providing the framework
REM !! For a new version entry, copy the last entry down and modify Date, Author and Description
SET version=%version: =%

REM.-- Set the window title
SET title=%~n0
TITLE %title%

REM.--initialize the variables
set FilePersist=%~dpn0+.cmd&     rem --define the filename where persistent variables get stored
set             SvrCli_choice=,Server,Client,
call:setPersist SvrCli=Server
set             bShowReadMe_choice=,Yes,No,
call:setPersist bShowReadMe=No
set             InstSize_choice=,Full,Regular,Mini,
call:setPersist InstSize=Full

rem.--read the persistent variables from the storage
call:restorePersistentVars "%FilePersist%"



:menuLOOP
echo.
echo.= Menu =================================================
echo.
for /f "tokens=1,2,* delims=_ " %%A in ('"findstr /b /c:":menu_" "%~f0""') do echo.  %%B  %%C
set choice=
echo.&set /p choice=Make a choice or hit ENTER to quit: ||(
    call:savePersistentVars "%FilePersist%"&   rem --save the persistent variables to the storage
    GOTO:EOF
)
echo.&call:menu_%choice%
GOTO:menuLOOP

::-----------------------------------------------------------
:: menu functions follow below here
::-----------------------------------------------------------

:menu_Options:

:menu_1   Install version              : '!SvrCli!' [!SvrCli_choice:~1,-1!]
call:getNextInList SvrCli "!SvrCli_choice!"
cls
GOTO:EOF

:menu_2   Size of installation         : '!InstSize!' [!InstSize_choice:~1,-1!]
call:getNextInList InstSize "!InstSize_choice!"
cls
GOTO:EOF

:menu_3   Show Readme.txt when finished: '!bShowReadMe!' [!bShowReadMe_choice:~1,-1!]
call:getNextInList bShowReadMe "!bShowReadMe_choice!"
cls
GOTO:EOF

:menu_
:menu_Execute:

:menu_I   Start Installation (simulation only)

set maxcnt=20
if /i "%InstSize:~0,1%"=="F" set maxcnt=11
if /i "%InstSize:~0,1%"=="R" set maxcnt=7
if /i "%InstSize:~0,1%"=="M" set maxcnt=3

echo.Simulating an installation for !maxcnt! files...
call:initProgress maxcnt
for /l %%C in (1,1,!maxcnt!) do (
    echo.Pretend to install !SvrCli! file %%C.
    call:sleep 1
    call:doProgress
)
call:sleep 1
TITLE %title%
if /i "%bShowReadMe:~0,1%"=="Y" notepad ReadMe.txt
GOTO:EOF

:menu_C   Clear Screen
cls
GOTO:EOF


::-----------------------------------------------------------
:: helper functions follow below here
::-----------------------------------------------------------


:setPersist -- to be called to initialize persistent variables
::          -- %*: set command arguments
set %*
GOTO:EOF


:getPersistentVars -- returns a comma separated list of persistent variables
::                 -- %~1: reference to return variable
SETLOCAL
set retlist=
set parse=findstr /i /c:"call:setPersist" "%~f0%"^|find /v "ButNotThisLine"
for /f "tokens=2 delims== " %%a in ('"%parse%"') do (set retlist=!retlist!%%a,)
( ENDLOCAL & REM RETURN VALUES
    IF "%~1" NEQ "" SET %~1=%retlist%
)
GOTO:EOF


:savePersistentVars -- Save values of persistent variables into a file
::                  -- %~1: file name
SETLOCAL
echo.>"%~1"
call :getPersistentVars persvars
for %%a in (%persvars%) do (echo.SET %%a=!%%a!>>"%~1")
GOTO:EOF


:restorePersistentVars -- Restore the values of the persistent variables
::                     -- %~1: batch file name to restore from
if exist "%FilePersist%" call "%FilePersist%"
GOTO:EOF


:getNextInList -- return next value in list
::             -- %~1 - in/out ref to current value, returns new value
::             -- %~2 - in     choice list, must start with delimiter which must not be '@'
SETLOCAL
set lst=%~2&             rem.-- get the choice list
if "%lst:~0,1%" NEQ "%lst:~-1%" echo.ERROR Choice list must start and end with the delimiter&GOTO:EOF
set dlm=%lst:~-1%&       rem.-- extract the delimiter used
set old=!%~1!&           rem.-- get the current value
set fst=&for /f "delims=%dlm%" %%a in ("%lst%") do set fst=%%a&rem.--get the first entry
                         rem.-- replace the current value with a @, append the first value
set lll=!lst:%dlm%%old%%dlm%=%dlm%@%dlm%!%fst%%dlm%
                         rem.-- get the string after the @
for /f "tokens=2 delims=@" %%a in ("%lll%") do set lll=%%a
                         rem.-- extract the next value
for /f "delims=%dlm%" %%a in ("%lll%") do set new=%%a
( ENDLOCAL & REM RETURN VALUES
    IF "%~1" NEQ "" (SET %~1=%new%) ELSE (echo.%new%)
)
GOTO:EOF


:initProgress -- initialize an internal progress counter and display the progress in percent
::            -- %~1: in  - progress counter maximum, equal to 100 percent
::            -- %~2: in  - title string formatter, default is '[P] completed.'
set /a ProgressCnt=-1
set /a ProgressMax=%~1
set ProgressFormat=%~2
if "%ProgressFormat%"=="" set ProgressFormat=[PPPP]
set ProgressFormat=!ProgressFormat:[PPPP]=[P] completed.!
call :doProgress
GOTO:EOF


:doProgress -- display the next progress tick
set /a ProgressCnt+=1
SETLOCAL
set /a per=100*ProgressCnt/ProgressMax
set per=!per!%%
title %ProgressFormat:[P]=!per!%
GOTO:EOF




FOR /l %%a in (%~1,-1,1) do (ping -n 2 -w 1 127.0.0.1>NUL)
goto :eof
