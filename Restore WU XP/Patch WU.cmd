@cls
@ECHO OFF
setLocal EnableExtensions EnableDelayedExpansion
title Un-Official Windows Update Restore Tool

ECHO.
cd /d "%~dp0"
call :SetLocalDefination

>nul 2>&1 fltmc || (
	>"%temp%\Elevate.vbs" echo CreateObject^("Shell.Application"^).ShellExecute "%~dpfx0", "%*" , "", "runas", 1
	>nul "%temp%\Elevate.vbs" & del /q "%temp%\Elevate.vbs"
	exit)
	
REM ECHO Installing Window Update ActiveX DLL
REM ECHO.

REM ren %System32%\muweb.dll muweb.%random% > NUL
REM ren %syswow64%\muweb.dll muweb.%random% > NUL
REM ren %System32%\mucltui.dll mucltui.%random% > NUL
REM ren %syswow64%\mucltui.dll mucltui.%random% > NUL
REM ren %System32%\MicrosoftUpdateCatalogWebControl.dll MicrosoftUpdateCatalogWebControl.%random% > NUL
REM ren %syswow64%\MicrosoftUpdateCatalogWebControl.dll MicrosoftUpdateCatalogWebControl.%random% > NUL

REM copy ActiveX\%OSArchitecture%\* %System32% > NUL
REM RegSvr32 /s %System32%\muweb.dll
REM RegSvr32 /s %System32%\mucltui.dll
REM RegSvr32 /s %System32%\MicrosoftUpdateCatalogWebControl.dll

ECHO.
ECHO Replacing wuaueng.dll with patched file
ECHO.

del %System32%\Dllcache\wuaueng.dll > NUL
ren %System32%\wuaueng.dll wuaueng.%random% > NUL
copy %OSArchitecture%\wuaueng.dll %System32% > NUL
RegSvr32 /s %System32%\wuaueng.dll > NUL

del %syswow64%\Dllcache\wuaueng.dll > NUL
ren %syswow64%\wuaueng.dll wuaueng.%random% > NUL
copy %OSArchitecture%\wuaueng.dll %syswow64% > NUL
RegSvr32 /s %syswow64%\wuaueng.dll > NUL

ECHO Disable Genuine Check Via hosts File
ECHO.
1>nul 2>nul rd/s/q "%ALLUSERSPROFILE%\application data\Office Genuine Advantage"
1>nul 2>nul rd/s/q "%ALLUSERSPROFILE%\Office Genuine Advantage"
1>nul 2>nul rd/s/q "%ALLUSERSPROFILE%\application data\Windows Genuine Advantage"
1>nul 2>nul rd/s/q "%ALLUSERSPROFILE%\Windows Genuine Advantage"

set "hosts=%windir%\system32\drivers\etc\hosts"
attrib %hosts% -a -r -s -h 
>>%hosts% echo.
>>%hosts% echo 127.0.0.1 localhost
>>%hosts% echo 127.0.0.1 mpa.one.microsoft.com 
>>%hosts% echo 127.0.0.1 sls.microsoft.com 
>>%hosts% echo 127.0.0.1 genuine.microsoft.com
>>%hosts% echo 127.0.0.1 wat.microsoft.com
1>nul 2>nul attrib +a +r +s +h %hosts%
1>nul 2>nul ipconfig /flushdns

1>nul 2>nul bootcfg /raw /fastdetect /id 1

shutdown -r -t 0
goto :eof

:SetLocalDefination
set "CFF=cscript Add-ins\QueryTool.vbs /QUERY_BASIC AddressWidth Win32_Processor"
for /f "tokens=1 skip=3 delims=," %%g in ('!CFF!') do set "OSArchitecture=%%g"

set "CFF=cscript Add-ins\QueryTool.vbs /QUERY_BASIC BuildNumber Win32_OperatingSystem"
for /f "tokens=1 skip=3 delims=," %%g in ('!CFF!') do set "OSBuildNumber=%%g"

set "CFF=cscript Add-ins\QueryTool.vbs /QUERY_BASIC OSLanguage Win32_OperatingSystem"
for /f "tokens=2 skip=3 delims=," %%g in ('!CFF!') do set "OSLanguage=%%g"

set "System32=%SystemRoot%\System32"
set "syswow64=%SystemRoot%\syswow64"

IF %OSArchitecture%==32 set "OSArchitecture=x86"
IF %OSArchitecture%==64 set "OSArchitecture=x64"

IF %OSLanguage%==2052 set OSLanguageID=CHS
IF %OSLanguage%==1028 set OSLanguageID=CHT
IF %OSLanguage%==1029 set OSLanguageID=CSY
IF %OSLanguage%==1031 set OSLanguageID=DEU
IF %OSLanguage%==1033 set OSLanguageID=ENU
IF %OSLanguage%==3082 set OSLanguageID=ESN
IF %OSLanguage%==1036 set OSLanguageID=FRA
IF %OSLanguage%==1038 set OSLanguageID=HUN
IF %OSLanguage%==1040 set OSLanguageID=ITA
IF %OSLanguage%==1041 set OSLanguageID=JPN
IF %OSLanguage%==1042 set OSLanguageID=KOR
IF %OSLanguage%==1043 set OSLanguageID=NLD
IF %OSLanguage%==1045 set OSLanguageID=PLK
IF %OSLanguage%==1046 set OSLanguageID=PTB
IF %OSLanguage%==2070 set OSLanguageID=PTG
IF %OSLanguage%==1049 set OSLanguageID=RUS
IF %OSLanguage%==1053 set OSLanguageID=SVE
IF %OSLanguage%==1055 set OSLanguageID=TRK
goto :eof
