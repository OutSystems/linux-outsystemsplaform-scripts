#!/bin/bash

# Change log
# v1.0  * initial version
# v1.1  * collect thread dumps from outsystems services
#       * logs are now compressed into a single file
#       * minor code corrections and improvements

VERSION="1.1"

if [ ! -f /etc/sysconfig/outsystems ]; then
	echo "OutSystems Platform is not installed on this server. Cancelling."
	exit
fi

if [ $(whoami) != "root" ]; then
	echo "This script must be executed as root."
	exit
fi


source /etc/sysconfig/outsystems

echo ""
echo "OutSystems Thread Collector v$VERSION"
echo ""

THREAD_FOLDER="thread_dumps_$(date +%Y%m%d_%H%M)"

# Application server info
PROCESS_USER=""
APPSERVER_NAME=""

WEBLOGIC_NAME="WebLogic"
JBOSS_NAME="JBoss"
WILDFLY_NAME="Wildfly"

WL_ADMIN_SERVER_NAME="AdminServer"

# Number of total thread collections - Defaults to 1
COLLECT_TOTAL=1

# Time interval in seconds between thread collections - Defaults to 1 second
COLLECT_INTERVAL=1


# Check arguments for optional configurations
while [[ $# -gt 0 ]]
do
	option="$1"

	case $option in
		-n|--number)
			COLLECT_TOTAL=$2
			shift
			;;
		-i|--interval)
			COLLECT_INTERVAL=$2
			shift
			;;
		-h|--help)
			echo "Executing this script will collect a thread dump of your application server process. This works for WildFly, WebLogic and JBoss."
			echo "Options:"
			echo "    -n|--number [number_of_collections]: Allows you to perform sequential thread collections. The default number of collections is $COLLECT_TOTAL."
			echo "    -i|--interval [interval_in_seconds]: Interval between consecutive thread collections, specified in seconds. The default interval is $COLLECT_INTERVAL seconds."
			echo ""
			exit
			;;
		*)
			# unknown option
			;;
	esac
	shift # past argument or value
done




# Create temporary folder
DIR=$(mktemp -d)
chmod 777 $DIR
touch $DIR/errors.log
chmod 777 $DIR/errors.log


# Check which application server is the server running
if [ "$JBOSS_HOME" != "" ]; then
	APPSERVER_NAME="$JBOSS_NAME"
	PROCESS_USER="jboss"
	if [ -d $JBOSS_HOME/server/outsystems/ ]; then
		PROCESS_PID=$(ps -u $PROCESS_USER 2>>/dev/null | grep java | gawk '{print $1}')
	else
		if [ -f /var/run/jboss-as/jboss-as-standalone-outsystems.pid ]; then
			PROCESS_PID=$(cat /var/run/jboss-as/jboss-as-standalone-outsystems.pid)
		else
			PROCESS_PID=$(ps -ef | grep java.*standalone-outsystems.xml | grep -v grep | awk '{print $2}')
		fi
	fi
fi

if [ "$WILDFLY_HOME" != "" ]; then
       APPSERVER_NAME=$WILDFLY_NAME
       PROCESS_USER="wildfly"
       
       PROCESS_PID=$(ps -ef | grep java.*standalone-outsystems.xml | grep -v grep | awk '{print $2}')
       JBOSS_HOME=$WILDFLY_HOME
fi

if [ "$WL_DOMAIN" != "" ]; then
	APPSERVER_NAME="$WEBLOGIC_NAME"
	if [ "$PROCESS_USER" == "" ]; then
		PROCESS_USER=$(stat -c %U $WL_DOMAIN)
	fi
	
	if [ "$WL_MANAGED_SERVER_NAME" == "" ]; then
		PROCESS_PID=$(ps -u $PROCESS_USER --format "pid cmd" 2>>/dev/null | grep java | grep weblogic.Server | grep -v weblogic.Name=$WL_ADMIN_SERVER_NAME | gawk '{print $1}')
		WL_MANAGED_SERVER_NAME=$(ps --pid $PROCESS_PID --format cmd | grep java | sed 's/.*weblogic.Name=[ ]*\([^ ]*\).*/\1/g')
	else
		PROCESS_PID=$(ps -u $PROCESS_USER --format "pid cmd" 2>>/dev/null | grep java | grep weblogic.Server | grep weblogic.Name=$WL_MANAGED_SERVER_NAME | gawk '{print $1}')
	fi
fi

# Get java bin
JAVA_BIN=$(dirname "$(readlink /proc/$PROCESS_PID/exe)")

if [ -f $JAVA_BIN/../../bin/java ]; then
	JAVA_BIN="$JAVA_BIN/../../bin/"
fi


mkdir -p $THREAD_FOLDER/

# Collect the thread dumps
if [ "$PROCESS_PID" == "" ]; then
	echo "Could not find the $APPSERVER_NAME process."
else
	COLLECT_COUNT=0
	
	while [ $COLLECT_COUNT -lt $COLLECT_TOTAL ]; do
		let collect_print=COLLECT_COUNT+1
		
		echo "Collecting threads $collect_print of $COLLECT_TOTAL."
		
		TIMESTAMP=$(date +%F_%H%M%S)
		
		# Collect application server threads
		if [ -f $JAVA_BIN/jrcmd ]; then
			su $PROCESS_USER - -s /bin/bash -c "$JAVA_BIN/jrcmd $PROCESS_PID print_threads" > $DIR/threads_"$APPSERVER_NAME".log 2>> $DIR/errors.log
		else
			su $PROCESS_USER - -s /bin/bash -c "$JAVA_BIN/jstack $PROCESS_PID" > $DIR/threads_"$APPSERVER_NAME".log 2>> $DIR/errors.log
		fi
		
		FILENAME=$TIMESTAMP"_"$APPSERVER_NAME".log"
		cp $DIR/threads_$APPSERVER_NAME.log $THREAD_FOLDER/$FILENAME;
		
		
		# Collect OutSystems services threads
		for SERVICE_INFO in $(su outsystems -c "$JAVA_HOME/bin/jps -l" | grep outsystems.hubedition | tr ' ' '|')
		do
			eval $(echo "$SERVICE_INFO" | gawk -F "|" '{print "SERVICE_PID="$1";SERVICE_PROCESS_NAME="$2}')
			if [ -f $JAVA_HOME/bin/jrcmd ]; then
				su outsystems - -s /bin/bash -c "$JAVA_HOME/bin/jrcmd $SERVICE_PID print_threads > $DIR/threads_"$SERVICE_PROCESS_NAME".log 2>> $DIR/errors.log"
			else
				su outsystems - -s /bin/bash -c "$JAVA_HOME/bin/jstack $SERVICE_PID > $DIR/threads_"$SERVICE_PROCESS_NAME".log 2>> $DIR/errors.log"
			fi
			
			FILENAME=$TIMESTAMP"_"$SERVICE_PROCESS_NAME".log"
			cp $DIR/threads_$SERVICE_PROCESS_NAME.log $THREAD_FOLDER/$FILENAME;
			
		done
		
		
		let COLLECT_COUNT=COLLECT_COUNT+1
		
		if [ $COLLECT_TOTAL -gt 1 -a $COLLECT_COUNT -lt $COLLECT_TOTAL ]; then
			echo "Waiting $COLLECT_INTERVAL seconds for next collection."
			sleep $COLLECT_INTERVAL
		fi
	done
	
fi

# Package dumps
echo ""
echo "Packing information, please wait."
PACKAGE_TARGET="outsystems_thread_dumps_$(date +%Y%m%d_%H%M).tgz"
tar zcf $PACKAGE_TARGET -C $THREAD_FOLDER .
echo "Threads collected successfully. You can find them in $PACKAGE_TARGET ."
echo ""

# Delete the previously generated temporary folders
rm -rf $DIR
rm -rf $THREAD_FOLDER