#!/bin/bash

source /etc/sysconfig/outsystems

ESPACES=$(ls $JBOSS_HOME/standalone/deployments/ | grep \\.war$ | grep -v customHandlers | sed s/\\.war$// | sort)


for espace in $ESPACES; do
	cd $JBOSS_HOME/standalone/deployments/$espace.war
	echo $espace $(find -type f -or -type l | sort | xargs md5sum | md5sum | awk '{print $1}')
done
