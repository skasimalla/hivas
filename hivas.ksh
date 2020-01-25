#!/bin/ksh
initialize()
{
. $AGENT/hivas.env

cd $AGENT
export dt=$(date +"%Y-%m-%d_%H:%M:%S")
export dt_numFormat=$(date +"%Y%m%d")

mv $AGENT/version.info  $AGENT/version.info.old
rm $boxname.ks*

if [ $ostype == 'AIX' ];then
wget http://$DevOpsServerAndPort/awp$SDLC_env/version.info || error_exit "Cannot access version file ! aborting .."
wget http://$DevOpsServerAndPort/awp$SDLC_env/custom/$boxname.ksh

elif [ $ostype == 'Linux' ];then
curl -O http://$DevOpsServerAndPort/awp$SDLC_env/version.info || error_exit "Cannot access version file ! aborting .."
curl -O  http://$DevOpsServerAndPort/awp$SDLC_env/custom/$boxname.ksh

elif [ $ostype == 'SunOS' ];then
wget http://$DevOpsServerAndPort/awp$SDLC_env/version.info || error_exit "Cannot access version file ! aborting .."
wget http://$DevOpsServerAndPort/awp$SDLC_env/custom/$boxname.ksh

fi

}

editParams()
{

echo "Inside editParams"

}

upgrade()
{

#mv $AGENT/agent-commons-0.0.1-SNAPSHOT.zip $AGENT/agent-commons-0.0.1-SNAPSHOT.zip_$dt

if [ $ostype == 'AIX' ];then
wget http://$DevOpsServerAndPort/$SDLC_env/agent.tar
elif [ $ostype == 'Linux' ];then
curl -O http://$DevOpsServerAndPort/$SDLC_env/agent.tar 
elif [ $ostype == 'SunOS' ];then
wget http://$DevOpsServerAndPort/$SDLC_env/agent.tar
fi

mkdir $AGENT/properties_temp
cp -R $AGENT/properties/* $AGENT/properties_temp
tar -xvf filewatcher.tar
cp -fR $AGENT/properties_temp/* $AGENT/properties

#tail -100 $AGENT/logs/AGENT.log | mail -s "Upgrade agent log on $boxname $AGENT " opsauto3@gmail.com
#$AGENT/sm.ksh "Upgrade agent log on $boxname $AGENT " $AGENT/nohup.out  $AGENT/properties/application.properties

}


killAgent()
{
echo "Attempting to kill agent"
ps -ef | grep com.xxx.Agent | grep -v grep | awk '{print $2}' | xargs -I {}  kill -9 {}

}


start()
{
nohup $JAVA_HOME_SAM/bin/java -Xms512m -Xmx1024m  -Dcom.sun.management.jmxremote.local.only=false -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=3690 -Dapp.env=$SDLC_env -cp $AGENTCLASSPATH com.xxx.Agent &

echo $dt_numFormat>strt.tym 

}


restart()
{

killAgent
sleep 3
echo "Restarting agent"
start
sleep 3
#tail -100 $AGENT/logs/AGENT.log | mail -s "Restart agent log on $boxname $AGENT " opsauto3@gmail.com
#$AGENT/sm.ksh "Restart agent log on $boxname $AGENT " $AGENT/nohup.out $AGENT/properties/application.properties
}


status()
{

localVersion=`cat $AGENT/version.info.old`
serverVersion=`cat $AGENT/version.info`

echo "Agent Version local is :$localVersion"
echo "Agent Version  on the server is :$serverVersion"

#NOTE this will only work for numbers
if [ $serverVersion -eq $localVersion ]
 then 
         echo "You have the latest agent"
 else 
        echo "Updating stale agent"
	killAgent
        upgrade
fi

lastStarted=`cat $AGENT/strt.tym`

if [ $lastStarted -eq $dt_numFormat ]
 then 
	echo "The agent has restarted today" 
 else 
	echo "Doing the daily restart" 
 	restart 
fi  

status=`ps auxww | grep -i com.xxxx.Agent | grep -v grep | wc -l`
if [ $status -gt 0 ]
then
        echo "Agent running"
else
        echo "Agent not running"
        restart
fi 

lastLine=`tail -1 $AGENT/${boxname}.ksh`
if [ $lastLine == '#Execute' ];then
ksh $AGENT/${boxname}.ksh
echo "The custom command is executed"
fi

}

function error_exit
{
        echo "$1" 1>&2
        exit 1
}


echo "Usage: feeds.ksh firstArg:LOCATION_OF_THE_INSTALLATION"
export AGENT=$1
initialize
status
cd -
exit
