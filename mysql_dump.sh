#!/bin/bash

# This script will backup one or more MySQL databases and
# dump database and table definitions for other databases
#
# This script will create a different backup file for each database by day of the month
#
############################################################

# Data backup (all databases specified here will have it's data backed up)
DATABASES="mysql"
DATABASE_LIST=$(mysql -NBe 'show schemas' | grep -wv 'information_schema\|performance_schema\|trouble_prod')

# Set to 1 to print all commands without running anything with side effects
DEBUG=0

############################################################

# Defaults file with credentials to MySQL
defaults_file=/home/mysql/.my.cnf

# Directory where you want the backup files to be placed
backupdir=/mnt/mysql-backup/dump

# MySQL dump command, use the full path name here
mysqldumpcmd=/usr/bin/mysqldump

# MySQL dump options
dumpoptions=" --quick --add-drop-table --add-locks --extended-insert --lock-tables --max_allowed_packet=512MB --single-transaction --triggers --routines"

# MySQL binary
MYSQL=/usr/bin/mysql

# GZip binary
gzip=/bin/gzip

############################################################

DOM="`date +%d`"

echo
echo -n "Starting dumping and compressing MySQL Databases ($1) at "
date
echo

RESTORE_CHECK=""
for database in $DATABASE_LIST
do
    RESTORE_CHECK="$database $RESTORE_CHECK"
    if [ "x${DEBUG}" == "x1" ]; then
        echo "mkdir -p ${backupdir}/${database}" 
        echo "rm -f ${backupdir}/${database}/${DOM}-${database}.sql.gz"
        echo "echo show master status | $MYSQL --defaults-file=$defaults_file \> ${backupdir}/$database/${DOM}-${database}-master-status-before.txt"
        echo "$mysqldumpcmd --defaults-file=$defaults_file $dumpoptions $database \| $gzip \> ${backupdir}/$database/${DOM}-${database}.sql.gz"
        echo "echo show master status | $MYSQL --defaults-file=$defaults_file \> ${backupdir}/$database/${DOM}-${database}-master-status-after.txt"
        echo "ls -lh ${backupdir}/$database/${DOM}-${database}.sql.gz"
    else
        mkdir -p ${backupdir}/${database}
        rm -f ${backupdir}/${database}/${DOM}-${database}.sql.gz
        $mysqldumpcmd --defaults-file=$defaults_file $dumpoptions $database | $gzip > ${backupdir}/$database/${DOM}-${database}.sql.gz
        ls -lh ${backupdir}/$database/${DOM}-${database}.sql.gz
    fi
done

echo $RESTORE_CHECK > $backupdir/restore_check.lst

echo -n "Dump Complete at "
date

if [ "x${DEBUG}" == "x1" ]; then
  echo mkdir -p ${backupdir}/definition_dump
  echo $mysqldumpcmd --defaults-file=$defaults_file $dumpoptions --no-data --all-databases $gzip ${backupdir}/definition_dump/${DOM}-all-db-table-definitions.sql.gz
else
  mkdir -p ${backupdir}/definition_dump
  $mysqldumpcmd --defaults-file=$defaults_file $dumpoptions --no-data --all-databases | $gzip > ${backupdir}/definition_dump/${DOM}-all-db-table-definitions.sql.gz
fi

echo
echo -n "Dumping database and table definitions:"
echo "Done!"

exit 0
