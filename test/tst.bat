@echo off
REM T S T
REM tst last edited on Fri Jun 21 23:26:28 2024

REM To redirect both stdout and stderr to a file, use > and 2>&1
REM Example: tst.bat > outputFile 2>&1

set EXE=julia ..\bfbs.jl
set TEN_PLUSS=++++++++++

REM Test if no options mode has any sensitivity to file length or number of columns
echo.
echo %TEN_PLUSS% %EXE% -d " " data.dat +++Small valid 3 column file, no options check%TEN_PLUSS%
%EXE% -d " " data.dat
REM Get the return code
echo %TEN_PLUSS% Shell got Return code number %ERRORLEVEL% for small valid file data.dat, no options check%TEN_PLUSS%

REM Test if no options mode has any sensitivity to file length or number of columns
echo.
echo %TEN_PLUSS% %EXE% data.csv +++Small valid 3 column file, no options check%TEN_PLUSS%
%EXE% data.csv
REM Get the return code
echo %TEN_PLUSS% Shell got Return code number %ERRORLEVEL% for small valid file data.csv, no options check%TEN_PLUSS%

REM Test if no options mode has any sensitivity to file length or number of columns
echo.
echo %TEN_PLUSS% %EXE% -d "\t" data.tab +++Small valid 3 column file, no options check%TEN_PLUSS%
%EXE% -d "\t" data.tab
REM Get the return code
echo %TEN_PLUSS% Shell got Return code number %ERRORLEVEL% for small valid file data.tab, no options check%TEN_PLUSS%

REM Test if no options mode has any sensitivity to file length or number of columns
echo.
echo %TEN_PLUSS% %EXE% -d ";" data.txt +++Small valid 3 column file, no options check%TEN_PLUSS%
%EXE% -d ";" data.txt
REM Get the return code
echo %TEN_PLUSS% Shell got Return code number %ERRORLEVEL% for small valid file data.txt, no options check%TEN_PLUSS%

REM Test if no options mode has any sensitivity to file length or number of columns
echo.
echo %TEN_PLUSS% %EXE% cols7rows4.csv +++Small valid 7 column by 4 row file, no options check%TEN_PLUSS%
%EXE% cols7rows4.csv
REM Get the return code
echo %TEN_PLUSS% Shell got Return code number %ERRORLEVEL% for small valid file data.txt, no options check%TEN_PLUSS%
