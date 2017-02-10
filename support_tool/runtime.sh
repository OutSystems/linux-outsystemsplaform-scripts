#!/bin/bash


DIR=$1
CP='cp -p'

source /etc/sysconfig/outsystems

echo "Gathering OutSystems Services info ..."
for SERVICE_INFO in $(su outsystems -c "$JAVA_HOME/bin/jps -l" | grep outsystems.hubedition | tr ' ' '|')
do
	eval $(echo "$SERVICE_INFO" | gawk -F "|" '{print "SERVICE_PID="$1";SERVICE_PROCESS_NAME="$2}')
	if [ -f $JAVA_HOME/bin/jrcmd ]; then
		su outsystems - -s /bin/bash -c "$JAVA_HOME/bin/jrcmd $SERVICE_PID print_threads > $DIR/threads_"$SERVICE_PROCESS_NAME".log 2>> $DIR/errors.log"
	else
		su outsystems - -s /bin/bash -c "$JAVA_HOME/bin/jstack $SERVICE_PID > $DIR/threads_"$SERVICE_PROCESS_NAME".log 2>> $DIR/errors.log"
	fi
	pmap -d $SERVICE_PID > $DIR/pmap_$SERVICE_PROCESS_NAME
done
