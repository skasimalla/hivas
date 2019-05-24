REM Designed and developed by Sunny Bond
SET AGENT=%cd%
SET AGENTCLASSPATH=%cd%/lib/*
SET SDLC_env=uat1
SET COMPLETEHOSTNAME=%COMPUTERNAME%.%USERDNSDOMAIN%
SET JAVA_HOME=%AGENT%\jre
Set curDate=%date:~-10%
REM create a directory to install cygwin
mkdir Cygwin
cd Cygwin
SET CYGWININSTALLPATH=%cd%

REM Download and install Cygwin 
powershell -Command "(New-Object Net.WebClient).DownloadFile('http://awd:30210/share/cygwin-1.3.3 Lite.zip', '%AGENT%/cygwin-1.3.3 Lite.zip')"
powershell Command "(new-object -com shell.application).namespace('%CYGWININSTALLPATH%').CopyHere((new-object -com shell.application).namespace('%AGENT%\cygwin-1.3.3 Lite.zip').Items(),16)"

REM Download agent and jre
powershell -Command "(New-Object Net.WebClient).DownloadFile('http://awd:30210/%SDLC_env%/agent.tar', '%AGENT%/agent.tar')"
powershell -Command "(New-Object Net.WebClient).DownloadFile('http://awd:30210/javaVersions/jre7_Win64.tar', '%AGENT%/jre7_Win64.tar')"
powershell -Command "(New-Object Net.WebClient).DownloadFile('http://awd:30210/%SDLC_env%/version.info', '%AGENT%\version.info')"
REM setting the cygwin class path 
SET CYGWINCLASSPATH=%CYGWININSTALLPATH%\bin
cd %AGENT%
SET PATH=%PATH%;%CYGWINCLASSPATH%

REM extracting the agent and jre files
tar -xvf agent.tar
tar -xvf jre7_Win64.tar

REM removing the tar files
rm agent.tar
REM rm jre7_Win64.tar
rm 'cygwin-1.3.3 Lite.zip'

REM replacing the application properties severname
powershell -Command "((Get-Content %AGENT%\properties\application.properties) -replace 'agent.server  =', 'agent.server = %COMPLETEHOSTNAME%'.ToLower().trim() | Set-Content %AGENT%\properties\application.properties)

REM creating a file hivas.bat which executes the agent app
ECHO %JAVA_HOME%\bin\java -Xms512m -Xmx1024m  -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=3690 -Dapp.env=%SDLC_env% -cp lib/*;. com.as.agent.Startagent> hivas.bat

ECHO %curDate% >strt.txt
REM creating a status.bat file which checks whether agent instance is running,kill the process and restart.
SET CURRENTDRIVE=%AGENT:~0,2%
ECHO SET currentDate=%%date:~-10%%>run.bat
ECHO SET fileOldDate=%AGENT%\strt.txt>>run.bat
ECHO SET fileOldDate=%AGENT%\strt.txt>>run.bat
ECHO SET localVersion=%AGENT%\version.info.old>>run.bat
ECHO SET serverVersion=%AGENT%\version.info>>run.bat
ECHO SET CYGWINCLASSPATH=%CYGWININSTALLPATH%\bin>>run.bat
ECHO SET PATH=%%PATH%%;%%CYGWINCLASSPATH%%>>run.bat
ECHO ECHO *******************UPGRADE PART********************** >>run.bat
ECHO MOVE %AGENT%\version.info  %AGENT%\version.info.old >>run.bat
ECHO powershell -Command "(New-Object Net.WebClient).DownloadFile('http://awd:30210/%SDLC_env%/version.info', '%AGENT%\version.info')" >>run.bat
ECHO if  ^%%ERRORLEVEL^%% == 1 (>>run.bat
ECHO EXIT )>>run.bat
ECHO FOR /f "delims=" %%%%X IN (%%localVersion%%) DO SET localVersionNumber=%%%%X>>run.bat
ECHO FOR /f "delims=" %%%%X IN (%%serverVersion%%) DO SET serverVersionNumber=%%%%X>>run.bat


ECHO echo "Agent Version local is :%localVersion%"
ECHO echo "Agent Version  on the server is :%serverVersion%"

ECHO if not ^%%localVersionNumber^%% == ^%%serverVersionNumber^%% ( >>run.bat
ECHO echo "Updating stale agent" >>run.bat
ECHO FOR /F "usebackq tokens=5" %%%%i IN (`wmic PROCESS where ^^^"name like ^^^'%%%%cmd.exe%%%%^^^'^^^" get Processid^^^,Caption^^^,Commandline ^^^| findstr /r "hivas.bat"`) DO taskkill /t /f /pid %%%%i >>run.bat
ECHO FOR /F "usebackq tokens=7" %%%%i IN (`wmic PROCESS where ^^^"name like ^^^'%%%%java%%%%^^^'^^^" get Processid^^^,Caption^^^,Commandline ^^^| findstr /r "Startagent"`) DO taskkill /f /pid %%%%i >>run.bat
ECHO powershell -Command "(New-Object Net.WebClient).DownloadFile('http://awd:30210/%SDLC_env%/agent.tar', '%AGENT%\agent.tar')" >>run.bat     
ECHO %CURRENTDRIVE%>>run.bat
ECHO CD %AGENT% >>run.bat
ECHO mkdir %AGENT%\properties_temp >>run.bat
ECHO COPY  /Y %AGENT%\properties\* %AGENT%\properties_temp >>run.bat
ECHO tar -xvf agent.tar >>run.bat
ECHO rm agent.tar >>run.bat
ECHO COPY /Y %AGENT%\properties_temp\* %AGENT%\properties >>run.bat
ECHO START hivas.bat >>run.bat
ECHO EXIT )>>run.bat
ECHO ECHO *******************RUNNING INSTANCE ONCE PER DAY********************** >>run.bat
ECHO FOR /f "delims=" %%%%X IN (%%fileOldDate%%) DO SET filedatetime=%%%%X>>run.bat
ECHO if not ^%%filedatetime:~0,10^%% == ^%%currentDate^%%  ( >>run.bat
ECHO FOR /F "usebackq tokens=5" %%%%i IN (`wmic PROCESS where ^^^"name like ^^^'%%%%cmd.exe%%%%^^^'^^^" get Processid^^^,Caption^^^,Commandline ^^^| findstr /r "hivas.bat"`) DO taskkill /t /f /pid %%%%i >>run.bat
ECHO FOR /F "usebackq tokens=7" %%%%i IN (`wmic PROCESS where ^^^"name like ^^^'%%%%java%%%%^^^'^^^" get Processid^^^,Caption^^^,Commandline ^^^| findstr /r "Startagent"`) DO taskkill /f /pid %%%%i >>run.bat
ECHO %CURRENTDRIVE%>>run.bat
ECHO cd %AGENT% >>run.bat
ECHO ECHO ^%%currentDate^%% ^>strt.txt >>run.bat
ECHO start hivas.bat >>run.bat
ECHO EXIT )>>run.bat
ECHO ECHO *******************CHECK MORE THAN ONE INSTANCE RUNNING********************** >>run.bat
ECHO FOR /F "usebackq tokens=1" %%%%i IN (`wmic PROCESS where ^^^"name like ^^^'%%%%java%%%%^^^'^^^" get Processid^^^,Caption^^^,Commandline ^^^| find /c "Startagent"`) DO SET /A count=%%%%i >>run.bat
ECHO if not ^%%count^%% == 1 (>>run.bat
ECHO FOR /F "usebackq tokens=5" %%%%i IN (`wmic PROCESS where ^^^"name like ^^^'%%%%cmd.exe%%%%^^^'^^^" get Processid^^^,Caption^^^,Commandline ^^^| findstr /r "hivas.bat"`) DO taskkill /t /f /pid %%%%i >>run.bat
ECHO FOR /F "usebackq tokens=7" %%%%i IN (`wmic PROCESS where ^^^"name like ^^^'%%%%java%%%%^^^'^^^" get Processid^^^,Caption^^^,Commandline ^^^| findstr /r "Startagent"`) DO taskkill /f /pid %%%%i >>run.bat
ECHO %CURRENTDRIVE%>>run.bat
ECHO CD %AGENT% >>run.bat
ECHO ECHO ^%%currentDate^%% ^>strt.txt >>run.bat
ECHO start hivas.bat >>run.bat
ECHO EXIT )>>run.bat

EXIT




