@cls
@ECHO OFF

>nul 2>&1 fltmc || (
	>"%temp%\Elevate.vbs" echo CreateObject^("Shell.Application"^).ShellExecute "%~dpfx0", "%*" , "", "runas", 1
	>nul "%temp%\Elevate.vbs" & del /q "%temp%\Elevate.vbs"
	exit)
	
set Invisible="%temp%\Invisible.vbs"
set "ProxHTTPSProxy=%~dp0Server\ProxHTTPSProxy.exe"
set "FirewallPolicyKey=HKLM\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile\AuthorizedApplications\List"
>%Invisible% echo CreateObject^("Wscript.Shell").Run """" ^& WScript.Arguments^(0^) ^& """", 0, False

>nul 2>&1 reg add "%FirewallPolicyKey%" /f /v "%ProxHTTPSProxy%" /d "%ProxHTTPSProxy%:*:Enabled:ProxHTTPSProxy" /t REG_SZ
>nul 2>&1 tskill /a *ProxHTTPSProxy*
>nul 2>&1 TASKKILL /IM ProxHTTPSProxy.exe /f
cd /d "%~dp0Server"
if exist CA.crt goto:StartServer

:BEGIN
>nul 2>&1 rd/s/q Certs
>nul 2>&1 start wscript %Invisible% "%~dp0Server\ProxHTTPSProxy.exe"
>nul 2>&1 ping 0.0.0.0 -n 3 -w 10
>nul 2>&1 tskill /a *ProxHTTPSProxy*
>nul 2>&1 TASKKILL /IM ProxHTTPSProxy.exe /f

if not exist CA.crt echo.&echo ** Error - Missing CERT file.&pause&goto:eof
>nul 2>&1 certutil -delstore Root "ProxHTTPSProxy CA"
>nul 2>&1 start "" /min "certutil" -addstore -f "root" CA.crt
>nul 2>&1 ping 0.0.0.0 -n 2 -w 10

REM > "%temp%\tmp.vbs" echo set WshShell ^= WScript.CreateObject^("WScript.Shell"^)
REM >> "%temp%\tmp.vbs" echo WshShell.SendKeys"Y"
REM >> "%temp%\tmp.vbs" echo WshShell.SendKeys"Y"
REM >nul 2>&1 cscript "%temp%\tmp.vbs"
REM >nul 2>&1 ping 0.0.0.0 -n 2 -w 10

2>nul certutil -store Root | >nul find /i "ProxHTTPSProxy CA" || (
	>nul 2>&1 del /q CA.crt
	echo.
	echo ** Error - Fail to install CERT file.
	pause
	goto:eof
)

:StartServer
2>nul certutil -store Root | >nul find /i "ProxHTTPSProxy CA" || (
	>nul 2>&1 del /q CA.crt
	goto:BEGIN
)
set "HASh="
for /f "tokens=* skip=25" %%g in ('2^>nul certutil -verify CA.crt') do (
	if not defined HASh (
		echo '%%g' | >nul find /i "ProxHTTPSProxy" || (
			echo '%%g' | >nul find /i "Serial" || (
				set "HASh=%%g"
			)
		)
	)
)
if not defined hash (
	>nul 2>&1 del /q CA.crt
	goto:BEGIN
)
2>nul certutil -Store Root | >nul find /i "%HASH%" || (
	echo.
	echo Found Hash : '%HASH%'
	echo.
	echo ** Error - Diffrent hash exist in Root Store
	echo ** Error - Generate new Certificate file
	>nul 2>&1 del /q CA.crt
	goto:BEGIN
)

echo.
echo Found Hash : '%HASH%'
echo.
echo Start Server
echo.
>nul 2>&1 ping 0.0.0.0 -n 2 -w 10
>nul 2>&1 start wscript %Invisible% "%~dp0Server\ProxHTTPSProxy.exe"