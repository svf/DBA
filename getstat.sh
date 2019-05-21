#!/usr/bin/env bash
# Get stats
#set -xv

file='gstat'
timelog='/home/mysql/.scripts/gstat'; export timelog
ADMINEMAIL="test@test.com"
DBCONF="/home/mysql/.scripts/.db.conf"
echo " " >> $timelog/$file-chk.log
echo "started" `date` >> $timelog/$file-chk.log

source ${DBCONF}
cat > /home/mysql/.scripts/mailtext1 << ++
Hello...

There are increased db activities.  Please review  the attachment(s).

Regards,
Engineering
++

SQ=$( mysql -h ${h1} -u ${blursr} -p${roof} -BNe "SELECT processlist_id as id FROM performance_schema.threads WHERE  processlist_state <> '' and processlist_info is not null" 2>/dev/null | wc -l)
SQ2=$( mysql -h ${h1} -u ${blursr} -p${roof} -BNe "SELECT processlist_id as id FROM performance_schema.threads WHERE  processlist_state <> '' and processlist_info like 'INSERT%' or  processlist_info like 'UPDATE%'" 2>/dev/null | wc -l)

Q1 () {
   mysqladmin -h ${h1} -u ${blursr} -p${roof} proc stat > $timelog/proc-stat-$(date +%F-%R).out
}
Q2 () {
     mysql -h ${h1} -u ${blursr} -p${roof} -e "show engine innodb status\G" > $timelog/innodbstatus-$(date +%F-%R).out
}
Q3 () {
    mysql -h ${h1} -u ${blursr} -p${roof} -t mysql <<QUERY_INPUT
    SELECT * INTO OUTFILE '/tmp/mysql_share/gstatus-$(date +%F-%R).csv'
    FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\r\n'
    FROM information_schema.global_status
    ORDER BY 1;
QUERY_INPUT
}

if [[ ${SQ} -gt "5" ]]
  then
   echo "   Retrieving proc stat" >> $timelog/$file-chk.log
   Q1 2>/dev/null
   Q3 2>/dev/null
   (cat /home/mysql/.scripts/mailtext1;) | mail -a /tmp/mysql_share/gstatus-$(date +%F-%R).csv -a $timelog/proc-stat-$(date +%F-%R).out  -s "WARNING: status on `hostname`" $ADMINEMAIL
   echo "   Finish retrieving" >> $timelog/$file-chk.log
   echo "ended" `date` >> $timelog/$file-chk.log
fi

if [[ ${SQ2} -gt "0" ]]
  then
   echo "   Checking DML" >> $timelog/$file-chk.log
   Q1 2>/dev/null
   Q2 2>/dev/null 
   Q3 2>/dev/null
   [ "$( grep "DETECTED DEADLOCK"  $timelog/innodbstatus-$(date +%F-%R).out)" ] && echo "Not Empty" || echo "Empty"
     CODE="$?"
        if [ ${CODE} -ne "0" ]; then
           echo "File is NOT empty exited with code ${CODE} on $(hostname)" >> $timelog/$file-chk.log
           (cat /home/mysql/.scripts/mailtext1;) | mail -a /tmp/mysql_share/gstatus-$(date +%F-%R).csv -a $timelog/proc-stat-$(date +%F-%R).out -a $timelog/innodbstatus-$(date +%F-%R).out -s "INFO: DML w lock on `hostname`" $ADMINEMAIL
           exit 1
        else
           echo "   File is empty with code ${CODE}"  >> $timelog/$file-chk.log
           (cat /home/mysql/.scripts/mailtext1;) | mail -a /tmp/mysql_share/gstatus-$(date +%F-%R).csv -a $timelog/proc-stat-$(date +%F-%R).out  -s "INFO: DML on `hostname`" $ADMINEMAIL
           echo "   Finish checking DML" >> $timelog/$file-chk.log
        fi
fi
echo "ended" `date` >> $timelog/$file-chk.log
exit 0
