#!/bin/bash

source /etc/sysconfig/outsystems

ESPACES=$(ls $OUTSYSTEMS_HOME/share | grep \\.war$ | grep -v customHandlers | sed s/\\.war$// | sort)

for espace in $ESPACES; do
	cd $OUTSYSTEMS_HOME/share/$espace/full/lib
	echo $espace $(find -name '*.jar' | sort | xargs md5sum | md5sum | awk '{print $1}')
done
