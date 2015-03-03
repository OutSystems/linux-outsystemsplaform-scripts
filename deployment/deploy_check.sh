#!/bin/bash

source /etc/sysconfig/outsystems

ESPACES=$(ls $JBOSS_HOME/standalone/deployments/ | grep \\.war$ | grep -v customHandlers | sed s/\\.war$// | sort)


for espace in $ESPACES; do
	cd $JBOSS_HOME/standalone/deployments/$espace.war
	find -type f -or -type l | sort | xargs md5sum > /tmp/$espace.os.md5
	echo $espace $(md5sum /tmp/$espace.os.md5 | awk '{print $1}')
done

tar -zcf /tmp/deploy_check.tgz  /tmp/*.os.md5 
