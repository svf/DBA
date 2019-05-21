#!/usr/bin/env bash
######################################################################
# Created By Scott Vranesh-Fallin July 1, 2017
# Purpose: Working Centos 7 MySQL Database Backups and 7+ day Purge
######################################################################
#set -xv

DBCONF="/home/mysql/.scripts/.db.conf"
BKDIR="/mysql/backups"
BKDIR2="/mysql/backups/"
ADMINEMAIL="test@test.com"
FD=$( find ${BKDIR2}  \! -name backups -prune -type d -mtime +7 -exec ls -d  '{}' \;)
FDD=$( find ${BKDIR2}  \! -name backups -prune -type d -mtime +7 -exec rm -r  '{}' \; -print >> /home/mysql/.scripts/delete.log)
OPT2="--skip-opt --single-transaction --routines --hex-blob --add-drop-table --create-options --quick --extended-insert --set-charset --disable-keys --master-data=2 --skip-add-locks --skip-lock-tables --default-character-set=utf8 -F "

# Log directories being purged
echo "#--- $(date +%F)"  >> /home/mysql/.scripts/delete.log

[[ -d ${BKDIR2} ]] &&
     echo -e "\nDirectories exist:\n \
     ${FD} \
     \nand are over 7+ days old. Deleting dirs now!"; \
sleep 2
     ${FDD} || exit 1
sleep 5

cd ${BKDIR}; mkdir $(date +%F-%R); cd $(date +%F-%R)
   echo -e "new backup dir is \n$PWD\n";
sleep 2

# Do separate backups for each databases
source ${DBCONF}
for I in $(mysql -h ${h1} -u ${blursr} -p${roof} -e 'show databases' -s --skip-column-names);
#for I in $(mysql -e 'show databases' -s --skip-column-names);

     do mysqldump $I -h ${h1} -u ${blursr} -p${roof} ${OPT2} > $I-full-$(hostname).sql
     status=$?
     if [ $status -ne 0 ]; then
          echo "The command \"mysqldump\" on $I failed with Error: ${status} and Pipestatus: ${PIPESTATUS[0]}" |  mailx -s "`hostname`: Check the last MySQL backup" $ADMINEMAIL
          exit 1;
     else
          echo "Database dump successfully!  Pipe status is: ${PIPESTATUS[0]}" 
     fi
     gzip -9 "$I-full-$(hostname).sql";
done

# Final error check
if [ -n "$status" ];
then
    echo "Database dump successfully!  Dump status is: ${status} "  |  mailx -s "`hostname`: MySQL backup ran successfully" $ADMINEMAIL 
else
    echo "The commands \"mysql\" and \"gzip\" failed with Error: ${status}" | mailx -s "`hostname`: Check the last MySQL backup" $ADMINEMAIL
    exit 1;
fi

exit 0


