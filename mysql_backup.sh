#!/bin/bash

DATADIR='/data/mysql/data/'
BACKUPDIR='/data/mysql/backups/'
BACKUPAGE=3

HOST_MASTER=$1

source /data/bin/mysql_credentials

if [ "x$1" == "x" ]; then
        echo "no IP given as argument"
        exit 1
fi

echo "check for mysql"
MYSQL=`type -p mysql` || exit 1
echo "check for mysqldump"
MYSQLDUMP=`type -p mysqldump` || exit 1
echo "check for gzip"
GZIP=`type -p gzip` || exit 1
echo "check for find"
FIND=`type -p find` || exit 1

MYSQLDUMP_OPT="--skip-opt --add-drop-table --create-options --extended-insert --quick --set-charset --hex-blob"
echo "Backupping to directory ${BACKUPDIR}"

BACKUPDATE=`date +%Y%m%d_%H%M`
mkdir -p $BACKUPDIR || exit 1


for db in `find ${DATADIR}/* -maxdepth 1 -type d 2>/dev/null` ; do
        DBNAME=`basename $db`
        $MYSQL -h $HOST_MASTER -u $USER_MASTER -p$PASS_MASTER -e "STOP SLAVE SQL_THREAD;"
        echo "`date +%Y%m%d_%H%M%S` dump database '$DBNAME'"
        if [ "x$DBNAME" != "x" ]; then
                if [ "$DBNAME" == "mysql" ]; then
                        $MYSQLDUMP -h $HOST_MASTER -u $USER_MASTER -p$PASS_MASTER -B $DBNAME --master-data=1 | $GZIP -9 > ${BACKUPDIR}/${DBNAME}_${BACKUPDATE}.sql.gz
                else 
                        $MYSQLDUMP $MYSQLDUMP_OPT -h $HOST_MASTER -u $USER_MASTER -p$PASS_MASTER -B $DBNAME | $GZIP -9 > ${BACKUPDIR}/${DBNAME}_${BACKUPDATE}.sql.gz
                fi
        fi
        $MYSQL -h $HOST_MASTER -u $USER_MASTER -p$PASS_MASTER -e "START SLAVE;"
done


$FIND $BACKUPDIR -type f -name \*.sql.gz -mtime +$BACKUPAGE -exec rm -v {} \;

