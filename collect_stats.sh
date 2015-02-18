#!/bin/bash

# Change log
# v1.1  * initial version
# v1.2  * memory default dump answer is now "no"
#       * don't run if platform is not detected to be installed       
# v1.3  * added weblogic patch information
# v1.4  * added iptables-save and prefs.xml
# v1.5  * added chkconfig info to iptables
#       * platform and application server logs limited to last month (configurable)
#       * admin server threads added
#       * only ls h2 dir if it exists
# v1.6  * added support for jboss 7
# v1.7  * added mq logs, heap and thread dumps
# v1.8  * added memory usage listing
# v1.9  * added /var/log/messages
#       * don't finish script prematurely if jboss or logs folder is not found
#       * show errors when there are any
#       * change sudo to su
# v1.10 * Require root to run.
# v1.11 * fix not collecting jboss data in jboss eap installations


# TODO
#      * separate logs into folders for easier navigation

#Configurable variables -- script usually does a decent job at figuring these out
WL_ADMIN_SERVER_NAME="AdminServer"
WL_MANAGED_SERVER_NAME=""
PROCESS_USER=""
LOGDAYS=30

# prepare for execution
echo "OutSystems Information Retriever v1.11"
echo

if [ ! -f /etc/sysconfig/outsystems ]; then
	echo "OutSystems Platform is not installed on this server. Cancelling."
	exit
fi

if [ $(whoami) != "root" ]; then
	echo "This script must be executed as root."
	exit
fi

source /etc/sysconfig/outsystems
CP='cp -p'
DIR=$(mktemp -d)
chmod 777 $DIR
touch $DIR/errors.log
chmod 777 $DIR/errors.log

APPSERVER_NAME="Application Server"
WEBLOGIC_NAME="WebLogic"
JBOSS_NAME="JBoss"

function askYesNo() {
	local answerYN="$1"

	echo -e -n "${*:2} [\e[49;32;3m$1\e[m] "

	read answerYN
	while [ "$answerYN" != "y" -a "$answerYN" != "n" -a "$answerYN" != "" ] ; do
		echo "Invalid value. Please write 'y' or 'n'"
		echo -e -n "${*:2} [\e[49;32;3m$1\e[m] "
		read answerYN
	done
	if [ "$answerYN" = "" ] ; then
			answerYN="$1"
	fi

	[ "$answerYN" = "y" ]
}

LOGS_FOLDER=""
if [ "$JBOSS_HOME" != "" ]; then
	APPSERVER_NAME="$JBOSS_NAME"
	PROCESS_USER="jboss"
	if [ -d $JBOSS_HOME/server/outsystems/ ]; then
		LOGS_FOLDER="$JBOSS_HOME/server/outsystems/log/"
		PROCESS_PID=$(ps -u $PROCESS_USER 2>>/dev/null | grep java | gawk '{print $1}')
	else
		LOGS_FOLDER="$JBOSS_HOME/standalone/log/"
		if [ -f /var/run/jboss-as/jboss-as-standalone-outsystems.pid ]; then
			PROCESS_PID=$(cat /var/run/jboss-as/jboss-as-standalone-outsystems.pid)
			PID_MQ=$(cat /var/run/jboss-as/jboss-as-standalone-outsystems-mq.pid)
		else
			PROCESS_PID=$(ps -ef | grep java.*standalone-outsystems.xml | grep -v grep | awk '{print $2}')
			PID_MQ=$(ps -ef | grep java.*standalone-outsystems-mq.xml | grep -v grep | awk '{print $2}')
		fi
	fi
fi

if [ "$WL_DOMAIN" != "" ]; then
	APPSERVER_NAME="$WEBLOGIC_NAME"
	if [ "$PROCESS_USER" == "" ]; then
		PROCESS_USER=$(stat -c %U $WL_DOMAIN)
	fi
	
	if [ "$WL_MANAGED_SERVER_NAME" == "" ]; then
		PROCESS_PID=$(ps -u $PROCESS_USER --format "pid cmd" 2>>/dev/null | grep java | grep weblogic.Server | grep -v weblogic.Name=$WL_ADMIN_SERVER_NAME | gawk '{print $1}')
		ADMINSERVER_PID=$(ps -u $PROCESS_USER --format "pid cmd" 2>>/dev/null | grep java | grep weblogic.Server | grep weblogic.Name=$WL_ADMIN_SERVER_NAME | gawk '{print $1}')
		WL_MANAGED_SERVER_NAME=$(ps --pid $PROCESS_PID --format cmd | grep java | sed 's/.*weblogic.Name=[ ]*\([^ ]*\).*/\1/g')
	else
		PROCESS_PID=$(ps -u $PROCESS_USER --format "pid cmd" 2>>/dev/null | grep java | grep weblogic.Server | grep weblogic.Name=$WL_MANAGED_SERVER_NAME | gawk '{print $1}')
	fi
	LOGS_FOLDER="$WL_DOMAIN/servers/$WL_MANAGED_SERVER_NAME/logs"
fi

JAVA_BIN=$(dirname "$(readlink /proc/$PROCESS_PID/exe)")

if [ -f $JAVA_BIN/../../bin/java ]; then
	JAVA_BIN="$JAVA_BIN/../../bin/"
fi

echo "OutSystems Platform Directory: $OUTSYSTEMS_HOME" >> $DIR/toolinfo
echo "Java Directory: $JAVA_BIN"  >> $DIR/toolinfo
echo "$APPSERVER_NAME user: $PROCESS_USER" >> $DIR/toolinfo
echo "$APPSERVER_NAME pid: $PROCESS_PID" >> $DIR/toolinfo
echo "$APPSERVER_NAME logs folder: $LOGS_FOLDER" >> $DIR/toolinfo
cat $DIR/toolinfo
echo


echo "Gathering OutSystems Logs..."
# OutSystems Logs
# $CP $OUTSYSTEMS_HOME/logs/*.log $DIR 2>> $DIR/errors.log
find $OUTSYSTEMS_HOME/logs/ -name '*.log' -ctime -$LOGDAYS -exec $CP \{\} $DIR \;


if [ "$LOGS_FOLDER" == "" ]; then
	echo "Invalid logs folder: '$LOGS_FOLDER'"
else
	echo "Gathering $APPSERVER_NAME Logs..."
	# Application Server Logs
	# $CP $LOGS_FOLDER/*.log* $DIR 2>> $DIR/errors.log
	find $LOGS_FOLDER/ -name '*.log*' -ctime -$LOGDAYS -exec $CP \{\} $DIR \;
	# $CP $LOGS_FOLDER/*.out* $DIR 2>> $DIR/errors.log
	find $LOGS_FOLDER/ -name '*.out*' -ctime -$LOGDAYS -exec $CP \{\} $DIR \;

	if [ -d $JBOSS_HOME/standalone/log-mq ] ; then
		mkdir $DIR/log-mq/
		find $JBOSS_HOME/standalone/log-mq/ -name '*.log*' -ctime -$LOGDAYS -exec $CP \{\} $DIR/log-mq/ \;
	fi
fi

echo "Gathering machine info..."
cat /proc/cpuinfo > $DIR/cpuinfo 2>> $DIR/errors.log 
cat /proc/meminfo > $DIR/meminfo 2>> $DIR/errors.log
df -h -l > $DIR/partInfo 2>> $DIR/errors.log
chkconfig --list iptables > $DIR/iptables_save
echo >> $DIR/iptables_save
/sbin/iptables-save >> $DIR/iptables_save 2>> $DIR/errors.log
ps -A -O pcpu,pmem,vsz > $DIR/ps 2>> $DIR/errors.log
$CP /var/log/messages* $DIR 2>> $DIR/errors.log


echo "Gathering java info..."
$JAVA_BIN/java -version 2> $DIR/javaVersion 

echo "Gathering platform info..."
# configurations
$CP /etc/outsystems/* $DIR 2>> $DIR/errors.log
# version
$CP $OUTSYSTEMS_HOME/version.txt $DIR 2>> $DIR/errors.log
# prefs
$CP /etc/.java/.systemPrefs/outsystems/prefs.xml $DIR 2>> $DIR/errors.log

if [ "$PROCESS_PID" == "" ]; then
	echo "Could not find the $APPSERVER_NAME process."
else
		echo "Gathering $APPSERVER_NAME (Process $PROCESS_PID) info..."
		echo "    * CPU statistics"
		# cpu status
		top -b -n 5 -p $PROCESS_PID > $DIR/cpu_"$APPSERVER_NAME".log 2>> $DIR/errors.log
		if [ -f $JAVA_BIN/jrcmd ]; then
			echo "    * Thread Stacks"
			su $PROCESS_USER - -c "$JAVA_BIN/jrcmd $PROCESS_PID print_threads > $DIR/threads_"$APPSERVER_NAME".log 2>> $DIR/errors.log"
			su $PROCESS_USER - -c "$JAVA_BIN/jrcmd $ADMINSERVER_PID print_threads > $DIR/threads_"$WL_ADMIN_SERVER_NAME".log 2>> $DIR/errors.log"
			echo "    * Java Counters"
			su $PROCESS_USER - -c "$JAVA_BIN/jrcmd $PROCESS_PID -l > $DIR/counters_"$APPSERVER_NAME".log 2>> $DIR/errors.log"
			echo "    * Object Summary"
			su $PROCESS_USER - -c "$JAVA_BIN/jrcmd $PROCESS_PID print_object_summary > $DIR/object_summary_"$APPSERVER_NAME".log 2>> $DIR/errors.log"
			echo "    * Heap Diagnostics"
			su $PROCESS_USER - -c "$JAVA_BIN/jrcmd $PROCESS_PID heap_diagnostics > $DIR/heap_diagnostics_"$APPSERVER_NAME".log 2>> $DIR/errors.log"
		else
			echo "    * Thread Stacks"
			su $PROCESS_USER - -c "$JAVA_BIN/jstack $PROCESS_PID > $DIR/threads_"$APPSERVER_NAME".log 2>> $DIR/errors.log"
			if [ -d $JBOSS_HOME/standalone/ ]; then
				su $PROCESS_USER - -c "$JAVA_BIN/jstack $PID_MQ > $DIR/threads_"$APPSERVER_NAME"_mq.log 2>> $DIR/errors.log"
			fi
		fi
fi

# Weblogic Specific
if [ "$APPSERVER_NAME" == "$WEBLOGIC_NAME" ]; then
	echo "    * Patch information"
	su $PROCESS_USER - -c "cd $MW_HOME/utils/bsu ; ./bsu.sh -prod_dir=$WL_HOME -status=applied -verbose -view > $DIR/weblogic_patches 2>> $DIR/errors.log"
fi


#JBoss Specific
if [ "$APPSERVER_NAME" == "$JBOSS_NAME" ]; then
	echo "    * Configurations"
	# H2 directory
	if [ -d $JBOSS_HOME/server/outsystems/data/h2/ ] ; then 
		ls -lh $JBOSS_HOME/server/outsystems/data/h2/ > $DIR/h2_dir
	fi
	
	# Configuration
	if [ -d $JBOSS_HOME/server/outsystems/ ]; then
		$CP $JBOSS_HOME/bin/run.sh $DIR 2>> $DIR/errors.log
		$CP $JBOSS_HOME/bin/run.conf $DIR 2>> $DIR/errors.log
		# jboss service configuration
		$CP $JBOSS_HOME/server/outsystems/conf/jboss-service.xml  $DIR 2>> $DIR/errors.log
		# jboss connectors
		$CP $JBOSS_HOME/server/outsystems/deploy/jbossweb.sar/server.xml $DIR 2>> $DIR/errors.log
	else
		$CP -r $JBOSS_HOME/standalone/configuration/ $DIR 2>> $DIR/errors.log
		$CP -r $JBOSS_HOME/standalone/configuration-mq/ $DIR 2>> $DIR/errors.log
		$CP $JBOSS_HOME/bin/standalone-outsystems.conf $DIR 2>> $DIR/errors.log
		$CP $JBOSS_HOME/bin/standalone-outsystems-mq.conf $DIR 2>> $DIR/errors.log
	fi
fi


echo "Gathering OutSystems Services info ..."
for SERVICE_INFO in $($JAVA_HOME/bin/jps -l | grep outsystems.hubedition | tr ' ' '|')
do
	eval $(echo "$SERVICE_INFO" | gawk -F "|" '{print "SERVICE_PID="$1";SERVICE_PROCESS_NAME="$2}')
	if [ -f $JAVA_HOME/bin/jrcmd ]; then
		su outsystems - -c "$JAVA_HOME/bin/jrcmd $SERVICE_PID print_threads > $DIR/threads_"$SERVICE_PROCESS_NAME".log 2>> $DIR/errors.log"
	else
		su outsystems - -c "$JAVA_HOME/bin/jstack $SERVICE_PID > $DIR/threads_"$SERVICE_PROCESS_NAME".log 2>> $DIR/errors.log"
	fi
done

if [ "$PROCESS_PID" == "" ]; then
	echo "not collecting memory dump because couldn't find process pid"
else
	if askYesNo "n" "Include $APPSERVER_NAME Memory Dump?"; then
		echo "Gathering $APPSERVER_NAME (Process $PROCESS_PID) memory dump..."
		# heap dump
		if [ -f $JAVA_BIN/jrcmd ]; then
			su $PROCESS_USER - -c "$JAVA_BIN/jrcmd $PROCESS_PID hprofdump filename=$DIR/heap.hprof > /dev/null 2>> $DIR/errors.log"
		else
			su $PROCESS_USER - -c "$JAVA_BIN/jmap -J-d64 -dump:format=b,file=$DIR/heap.hprof $PROCESS_PID > /dev/null 2>> $DIR/errors.log"
			if [ -d $JBOSS_HOME/standalone ]; then
				su $PROCESS_USER - -c "$JAVA_BIN/jmap -J-d64 -dump:format=b,file=$DIR/heap_mq.hprof $PID_MQ > /dev/null 2>> $DIR/errors.log"
			fi
		fi
	fi
fi

echo "Packing information, please wait."
PACKAGE_TARGET="$OUTSYSTEMS_HOME/outsystems_data_$(date +%Y%m%d_%H%M).tgz"
tar zcf $PACKAGE_TARGET -C $DIR .

echo "Information package created: $PACKAGE_TARGET"
echo "Done."

cat $DIR/errors.log

rm -rf $DIR
