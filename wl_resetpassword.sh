#!/bin/bash

# basis for this:
# http://www.oracle-base.com/articles/11g/reset-the-adminserver-password-in-weblogic-11g-and-12c.php

source /etc/sysconfig/outsystems
source $WL_DOMAIN/bin/setDomainEnv.sh

read -p "Username: " username
read -p "Password: " -s password
echo
read -p "Re-enter Password: " -s password2
echo

if [ $password != $password2 ] ; then
        echo "Passwords do not match, exiting..."
        exit
fi

# call password validator?

service weblogic-outsystems stop
service weblogic-outsystems-nodemanager stop
service weblogic-outsystems-adminserver stop

cd $WL_DOMAIN/security
$JAVA_HOME/bin/java weblogic.security.utils.AdminAccount $username $password .

chown wls_outsystems:wls_outsystems DefaultAuthenticatorInit.ldift

if [ -d $WL_DOMAIN/servers/AdminServer/data ]; then
        rm -rf $WL_DOMAIN/servers/AdminServer/data_old
        mv $WL_DOMAIN/servers/AdminServer/data  $WL_DOMAIN/servers/AdminServer/data_old
fi


mkdir -p $WL_DOMAIN/servers/AdminServer/security
cat > $WL_DOMAIN/servers/AdminServer/security/boot.properties <<EOF
username=$username
password=$password
EOF
chown -R wls_outsystems:wls_outsystems $WL_DOMAIN/servers/AdminServer/security

service weblogic-outsystems-adminserver start
service weblogic-outsystems-nodemanager start
service weblogic-outsystems start

echo
echo "You probably want to run $OUTSYSTEMS_HOME/configurationtool.sh and "
echo " configure the new username/password in the OutSystems.Weblogic configuration section"
echo
