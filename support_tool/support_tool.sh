#!/bin/bash

VERSION="2.0"

if [ ! -f /etc/sysconfig/outsystems ]; then
	echo "OutSystems is not installed on this server. Cancelling."
	exit
fi

if [ $(whoami) != "root" ]; then
	echo "This script must be executed as root."
	exit
fi

# if old version ( < 9.1 ) run old collect_stats script and exit?


source /etc/sysconfig/outsystems
CP='cp -p'
DIR=$(mktemp -d)
chmod 777 $DIR
touch $DIR/errors.log
chmod 777 $DIR/errors.log

echo "OutSystems Support Tool v$VERSION" >> $DIR/toolinfo
echo >> $DIR/toolinfo
echo "OutSystems platform Directory: $OUTSYSTEMS_HOME" >> $DIR/toolinfo

# this should be a module ?

if [ -h /opt -o -h /opt/outsystems -o -h /opt/outsystems/platform -o -h /opt/outsystems/platform/share ]; then
	echo >> $DIR/toolinfo
	echo "WARNING: OutSystems is installed on a symlink." >> $DIR/toolinfo
	echo "  From version 9.1 this may make it impossible to publish modules with web references." >> $DIR/toolinfo
	echo >> $DIR/toolinfo
fi

# use a more generic approach, with modules like the .d directories distros are using these days?

# gather information from system

./system.sh $DIR

# gather information from platform

./platform.sh $DIR

# gather information from application server

if rpm -q outsystems-agileplatform-wildfly8 > /dev/null ; then
  ./wildfly_8.sh $DIR
fi

if rpm -q outsystems-agileplatform-jboss6-eap > /dev/null ; then
  ./jboss_eap_6.sh $DIR
fi

if rpm -q outsystems-agileplatform-weblogic > /dev/null ; then
  ./weblogic.sh $DIR
fi

# gather runtime information

./runtime.sh $DIR


echo "Packing information, please wait."
PACKAGE_TARGET="$OUTSYSTEMS_HOME/outsystems_data_$(date +%Y%m%d_%H%M).tgz"
tar zcf $PACKAGE_TARGET -C $DIR .

echo "Information package created: $PACKAGE_TARGET"
echo "Done."

cat $DIR/errors.log

rm -rf $DIR
