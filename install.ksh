#!/bin/ksh


export AGENT=`pwd`
echo "export AGENT=$AGENT">hivas.env


export AGENTCLASSPATH=$AGENT:$AGENT/lib/*
echo "export AGENTCLASSPATH=$AGENTCLASSPATH">>hivas.env

timezone=`date |awk '{print $5}'`
echo "export timezone=$timezone">>hivas.env

export ostype=`uname`
echo "export ostype=$ostype">>hivas.env

export dt=$(date +"%Y-%m-%d_%H:%M:%S")
echo "export aw_install_dt=$dt">>hivas.env

export SDLC_env=dev
echo "export SDLC_env=$SDLC_env">>hivas.env

export DevOpsServerAndPort=server:30210
echo "export DevOpsServerAndPort=$DevOpsServerAndPort">>hivas.env

echo "1">$AGENT/strt.tym

echo "date>$AGENT/nohup.out">run.sh

echo ". $AGENT/hivas.env">>run.sh

echo "$AGENT/hivas.ksh $AGENT 1>>$AGENT/nohup.out 2>>$AGENT/nohup.out">>run.sh

if [ $ostype == 'AIX' ];then
wget http://$DevOpsServerAndPort/$SDLC_env/agent.tar
wget http://$DevOpsServerAndPort/$SDLC_env/hivas.ksh
wget http://$DevOpsServerAndPort/$SDLC_env/sm.ksh
wget http://$DevOpsServerAndPort/$SDLC_env/version.info
export boxname=`hostname`
echo "export boxname=$boxname">>hivas.env


elif [ $ostype == 'Linux' ];then
curl -O http://$DevOpsServerAndPort/$SDLC_env/agent.tar
curl -O http://$DevOpsServerAndPort/$SDLC_env/hivas.ksh
curl -O http://$DevOpsServerAndPort/$SDLC_env/sm.ksh
curl -O http://$DevOpsServerAndPort/$SDLC_env/version.info
export boxname=`hostname -f`
echo "export boxname=$boxname">>hivas.env

elif [ $ostype == 'SunOS' ];then
wget http://$DevOpsServerAndPort/$SDLC_env/agent.tar
wget http://$DevOpsServerAndPort/$SDLC_env/hivas.ksh
wget http://$DevOpsServerAndPort/$SDLC_env/sm.ksh
wget http://$DevOpsServerAndPort/$SDLC_env/version.info
export boxname=`hostname`
echo "export boxname=$boxname">>hivas.env


fi


tar -xvf agent.tar
rm agent.tar
mkdir archive

chmod -R 755 $AGENT/*
sed "s/agent_WIN_SS62841/$boxname/" $AGENT/properties/application.properties > tmp.file
mv tmp.file infile

export JAVA_HOME_=`whereis java | awk '{print $2}' | sed 's/\/bin\/java//g'`

statusJ=`$JAVA_HOME_/bin/java -version 2>&1 | grep 1.7 | wc -l`

if [ $statusJ -gt 0 ]
then
        echo "Java 7 present in path"
else
        echo "Java 7 NOT present in patht, doing a local installtion"

if [ $ostype == 'AIX' ];then
wget http://$DevOpsServerAndPort/javaVersions/jre7_${ostype}64.tar

elif [ $ostype == 'Linux' ];then
curl -O http://$DevOpsServerAndPort/javaVersions/jre7_${ostype}64.tar

elif [ $ostype == 'SunOS' ];then
wget http://$DevOpsServerAndPort/javaVersions/jre7_${ostype}64.tar
fi

tar -xvf jre7_${ostype}64.tar
export JAVA_HOME_=$AGENT/jre
rm jre7_${ostype}64.tar
fi

echo "export JAVA_HOME_=$JAVA_HOME_">>hivas.env
echo "#End Of env file">>hivas.env

echo "Please verify the contents of 1.> hivas.env and" 
echo "                              2.> properties/application.properties"

./sm.ksh " AGent Installation Successful" hivas.env

#write out current crontab
#crontab -l | grep -v $AGENT/run.sh >$AGENT/mycron.txt
#echo new cron into cron file
#echo "00,15,30,45 * * * * $AGENT/run.sh" >> mycron.txt
#install new cron file
#crontab $AGENT/mycron.txt

#cat run.sh
#./sm.ksh "Agent installed on $boxname $AGENT at $timezone $dt" $AGENT/hivas.env