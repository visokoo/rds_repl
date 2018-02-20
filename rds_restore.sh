#!/bin/bash
# grab latest backup from s3
set -e
DEST_FILE=backup.sql
DEST=/mnt/backup.sql.gz
S3_FILE=`s3cmd ls s3://<redacted>/mysql/full_mysql* | awk '/\.gz$/ { print $4 }' | tail -1`
s3cmd get $S3_FILE $DEST
cd `dirname $DEST`
echo `pwd`
echo "Doing gunzip"
gunzip `basename $DEST`
LOG_POS=`grep -m 1 '^CHANGE' $DEST_FILE | awk 'BEGIN { FS="=" } { sub(";", "", $5); print $5}'`
LOG_FILE=`grep -o -m 1 "MASTER_LOG_FILE='[[:alnum:].-]*" $DEST_FILE | cut -d\' -f2`
echo $LOG_FILE && echo $LOG_POS
mysql -e "CALL mysql.rds_stop_replication;"

# strip out anything that requires SUPER privileges
sed -i '22d;s/\/\*[^*]*DEFINER=[^*]*\*\///;s/DEFINER=`[a-z_]*`@`localhost` //' $DEST_FILE 

# strip out anything that requires SUPER privileges
mysql < $DEST_FILE | pv

mysql -e "CALL mysql.rds_set_external_master (
  '<redacted>'
  , 3306
  , '<redacted>'
  , '<redacted>'
  , '$LOG_FILE'
  , $LOG_POS
  , 0
); CALL mysql.rds_start_replication;"
rm $DEST_FILE
