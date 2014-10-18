#!/bin/bash

DIR=$(dirname $0)
DATE=$(date +%F)

# delete and archive the day's directory
tar -zcf "$DIR/${DATE}_$(hostname).tgz" $DIR/$DATE
rm -rf $DIR/$DATE

# delete archives older than 30 days
cd $DIR
find -name '*.tgz' -ctime +30 -exec rm -f \{\} \;

