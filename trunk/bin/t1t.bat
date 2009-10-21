@echo off
set dumvar=
rem Options: unfortunately, the stupid MSDOS command interpreter does not 
rem allow us to recognize if the first argument start with a '-', so we 
rem can only have a small number of specific option strings here.
set option=
:options
if "%1"=="-g" goto option
if "%1"=="-e" goto option
if "%1"=="-ge" goto option
if "%1"=="-eg" goto option
if "%1"=="-s" goto option
if "%1"=="+c" goto option
if "%1"=="+x" goto option
goto optok
:option
set option=%option% %1
shift
goto :options
:optok
echo options: %option%
if exist %1.ps set genps=rem
if "%2"=="" goto empty
if exist %2\nul goto dir

%genps% t1disasm %1.pfb %1.ps
t1tidy %option% %1.ps %2.ps
t1asm %2.ps %2.pfa
t1binary %2.pfa %2.pfb
%genps% del %1.ps
del %2.ps
del %2.pfa
goto end

:dir
%genps% t1disasm %1.pfb %1.ps
t1tidy %option% %1.ps %2
t1asm %2\%1.ps %2\%1.pfa
t1binary %2\%1.pfa %2\%1.pfb
%genps% del %1.ps
del %2\%1.ps
del %2\%1.pfa
goto end

:empty
echo No destination font file name given

:end
