#!/usr/bin/env bash
# Check for failed logins
#set -xv

file='flogin'
timelog='/home/mysql/.scripts'; export timelog
ADMINEMAIL="test@test.com"
GROUPEMAIL="test@test.com, testingtesting@test.com"
host=`echo "$(hostname)" | sed -e 's/^\(.\{15\}\).*/\1/'`
logfile='/mysql/log/'${host}
logfile=`echo "${logfile}.err"`

#echo " " >> $timelog/$file-chk.log
#echo "started" `date` >> $timelog/$file-chk.log

fsize=`du ${logfile} | cut -f 1`

if [ $fsize -gt 0 ];
  then
    #echo "   Checking access denied" >> $timelog/$file-chk.log
    if [ -f $timelog/$file-chk.out.1 ]
      then
        mv $timelog/$file-chk.out.1 $timelog/$file-chk.out.2
      else
        touch $timelog/$file-chk.out.2
      fi
      cat $logfile |grep "Access denied"  > $timelog/$file-chk.out.1;
      if [ "$( diff $timelog/$file-chk.out.1 $timelog/$file-chk.out.2)" ];
        then
          #echo "   Sending warning alert...Finish" >> $timelog/$file-chk.log
          #cat $timelog/$file-chk.out.1 | mail -s "Warning: MICS 7a Failed login on `hostname`" $ADMINEMAIL
          #diff $timelog/$file-chk.out.1 $timelog/$file-chk.out.2 | sed '1d' | mail -s "Warning: MICS 7a Failed login on `hostname`" $ADMINEMAIL
          diff $timelog/$file-chk.out.1 $timelog/$file-chk.out.2 | sed '1d' | mail -s "Warning: MICS 7a Failed login on `hostname`" $GROUPEMAIL
        else
          #printf "%s\nNo diff...will be del existing out1 \n"
          rm $timelog/$file-chk.out.1
          #echo "   Finish check" >> $timelog/$file-chk.log
      fi
    fi

#echo "ended" `date` >> $timelog/$file-chk.log

exit 0
