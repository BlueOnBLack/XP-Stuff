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

ECHO Adding registry entries
1>nul 2>nul reg import "add-ins\ZoneMap.reg"
1>nul 2>nul reg import "add-ins\tls 1.0.reg"
1>nul 2>nul reg import "add-ins\proxyXS.reg"
1>nul 2>nul reg import "add-ins\UW_Test.reg"
ECHO.

IF /i '%OSArchitecture%' equ 'x64' (
	ECHO Installing KB2868626 to enable SHA-256 support
	"x64\windowsserver2003.windowsxp-kb2868626-x64-%OSLanguageID%.exe" /q /n /z
	ECHO.
	
) else (
	ECHO Installing KB2868626 to enable SHA-256 support
	"x86\windowsserver2003-kb2868626-x86-%OSLanguageID%.exe" /q /n /z
	ECHO.
	
	ver | >nul find /i "5.1" && (
		ECHO Installing kb892130
		"x86\windowsxp-kb892130-x86-enu.exe" /q /n /z
		ECHO Installing kb898461
		"x86\windowsxp-kb898461-x86-enu.exe" /q /n /z
		ECHO.
	)
)


ECHO Updating Root Certificates
cd /d CERT
SET "DLURL=http://wsus.ds.download.windowsupdate.com/msdownload/update/v3/static/trustedr/en/"
for %%$ in (authroots.sst, delroots.sst, roots.sst, updroots.sst, disallowedcert.sst) do (
	>nul 2>&1 del /q "%Temp%\%%$"
	>nul 2>&1 wget.exe --no-verbose --output-document="%Temp%\%%$" -T 3 -c -S "%DLURL%/%%$"
	if exist "%Temp%\%%$" >nul 2>&1 copy /y "%Temp%\%%$"
)

for %%$ in (rootsupd.inf, rvkroots.inf, rvkroots.exe, updroots.exe) do 1>nul 2>&1 copy /y %%$ "%temp%"
for %%$ in (authroots.sst, delroots.sst, roots.sst, updroots.sst, disallowedcert.sst) do (if not exist "%temp%\%%$" 1>nul 2>&1 copy /y %%$ "%temp%")
pushd "%temp%"
Rundll32.exe advpack.dll,LaunchINFSection rootsupd.inf,DefaultInstall
Rundll32.exe advpack.dll,LaunchINFSection rvkroots.inf,DefaultInstall
popd
cd..
ECHO.

echo Install Administartion tools pack
>nul 2>&1 md "%temp%\ext"
>nul 2>&1 copy /y Add-ins\Certutil.cab "%temp%\ext"
>nul 2>&1 pushd "%temp%\ext"
>nul 2>&1 expand Certutil.cab * %system32%
>nul 2>&1 expand Certutil.cab * %syswow64%
>nul 2>&1 popd
>nul 2>&1 rd/s/q "%temp%\ext"
ECHO.
	
ECHO Installing latest Windows Update Agent
"%OSArchitecture%\WUA-Downlevel.exe" /quiet /norestart /wuforce
ECHO.

(2>nul reg query "HKEY_LOCAL_MACHINE\Software\Microsoft\Internet Explorer" /v "Version" | >nul find /i "8.") && (
	ECHO Installing Internet Explorer v8.0 [no necessary]
	ECHO.
) || (
	
	rem Backup Links
	rem https://dl.bobpony.com/software/ie/8/
	rem https://msdn.hackerc.at/Windows%20Internet%20Explorer%208/
	
	ECHO Installing Internet Explorer v8.0
	IF /i '%OSArchitecture%' equ 'x64' (
	
		rem For XP / Server
		>nul 2>&1 Add-ins\wget.exe --no-verbose --output-document="%Temp%\ie8-windowsserver2003-x64-enu.exe" -T 3 -c -S "http://download.windowsupdate.com/msdownload/update/software/uprl/2009/08/ie8-windowsserver2003-x64-enu_e658ac50c173116594b9f42a61b3ae6c22098c84.exe"
		>nul 2>&1 Add-ins\wget.exe --no-verbose --output-document="%Temp%\ie8postauprep.exe" -T 3 -c -S "http://download.windowsupdate.com/msdownload/update/software/uprl/2011/12/ie8postauprep_8f270d9c81873533b03be145b05ddd5b81cf66bd.exe"
		if exist "%Temp%\ie8-windowsserver2003-x64-enu.exe" "%Temp%\ie8-windowsserver2003-x64-enu.exe" /quiet /norestart
		if exist "%Temp%\ie8postauprep.exe" "%Temp%\ie8postauprep.exe" /quiet /norestart
		
	) else (
	
		rem For XP
		ver | >nul find /i "5.1" && (
			>nul 2>&1 Add-ins\wget.exe --no-verbose --output-document="%Temp%\ie8-windowsxp-x86-enu.exe" -T 3 -c -S "http://download.windowsupdate.com/msdownload/update/software/uprl/2009/08/ie8-windowsxp-x86-enu_808c1e22ea669ae931db841995f3ba211e00cd14.exe"
			>nul 2>&1 Add-ins\wget.exe --no-verbose --output-document="%Temp%\ie8postauprep.exe" -T 3 -c -S "http://download.windowsupdate.com/msdownload/update/software/uprl/2011/12/ie8postauprep_bdd9c4f020c3c51bedaf37db4b8d43afe07703fb.exe"
			if exist "%Temp%\ie8-windowsxp-x86-enu.exe" "%Temp%\ie8-windowsxp-x86-enu.exe" /quiet /norestart
			if exist "%Temp%\ie8postauprep.exe" "%Temp%\ie8postauprep.exe" /quiet /norestart
		)
		
		rem For Server
		ver | >nul find /i "5.2" && (
			>nul 2>&1 Add-ins\wget.exe --no-verbose --output-document="%Temp%\ie8-windowsserver2003-x86-enu.exe" -T 3 -c -S "http://download.windowsupdate.com/msdownload/update/software/uprl/2009/08/ie8-windowsserver2003-x86-enu_21da0baed38a94868cea572438bb31ab933c1f52.exe"
			if exist "%Temp%\ie8-windowsserver2003-x86-enu.exe" "%Temp%\ie8-windowsserver2003-x86-enu.exe" /quiet /norestart
		)
		
	)
	ECHO.
)

ECHO Create desktop shortcut for ProxHTTPSProxyMII
>nul 2>nul md "%APPDATA%\ProxHTTPSProxyMII_REV3a\Server"
>nul 2>nul xcopy /e /y ProxHTTPSProxyMII_REV3a "%APPDATA%\ProxHTTPSProxyMII_REV3a\Server"
>nul 2>nul copy /y "Start Server.cmd" "%APPDATA%\ProxHTTPSProxyMII_REV3a"
call :SR_Create "Start Server" "%APPDATA%\ProxHTTPSProxyMII_REV3a\Start Server.cmd" "%APPDATA%\ProxHTTPSProxyMII_REV3a\Server\ProxHTTPSProxy.exe" "%APPDATA%\ProxHTTPSProxyMII_REV3a"

1>nul 2>nul bootcfg /raw /fastdetect /id 1
1>nul 2>nul bootcfg /raw /a /safeboot:minimal /id 1

set "PatchWU=%~dp0Patch WU.cmd"
set "PatchWU_FIXED=%PatchWU:\=\\%
1>nul 2>nul reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" /v "*PatchWU" /f /t REG_SZ /d "\"%PatchWU_FIXED%\""

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

rem How to make a shortcut from CMD?
rem https://superuser.com/questions/392061/how-to-make-a-shortcut-from-cmd
rem https://admhelp.microfocus.com/uft/en/all/VBScript/Content/html/d91b9d23-a7e5-4ec2-8b55-ef6ffe9c777d.htm
rem https://docs.microsoft.com/en-us/troubleshoot/windows-client/admin-development/create-desktop-shortcut-with-wsh

:SR_Create
set "CreateShortcut=%temp%\CreateShortcut.vbs"
echo Set oWS = WScript.CreateObject("WScript.Shell") > "%CreateShortcut%"
echo sLinkFile = "%userprofile%\Desktop\%~1.lnk" >> "%CreateShortcut%"
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%CreateShortcut%"
echo oLink.TargetPath = "%~2" >> "%CreateShortcut%"
echo oLink.IconLocation  = "%~3" >> "%CreateShortcut%"
echo oLink.WorkingDirectory  = "%~4" >> "%CreateShortcut%"
echo oLink.Save >> "%CreateShortcut%"
>nul 2>&1 cscript "%CreateShortcut%"
del "%CreateShortcut%"
goto :eof
