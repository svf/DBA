#!/usr/bin/env bash
# Check for free disk space and alert as necessary
#set -xv
# Set admin email so that you can get email.
ADMINEMAIL="test@test.com"
ALERT=88
EXCLUDE_LIST="/platform|/cdrom"

main_prog() {
while read output;
do
#echo $output
usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1) 
partition=$(echo $output | awk '{print $2}') 
if [[ "$usep" -ge "$ALERT" ]] ; then
    echo "Running out of space \"$partition ($usep%)\" on server $(hostname), $(date)" |  mailx -s "Alert: Almost out of disk space $usep%" ${ADMINEMAIL} 
fi done 
}

if [[ "$EXCLUDE_LIST" != "" ]] ; then
   df -hl | egrep -v "^swap|tmp|sbin|${EXCLUDE_LIST}" | awk '{print $5 " " $6}' | main_prog
else
   df -hl | egrep -v "^swap|tmp|sbin" | awk '{print $5 " " $6}' | main_prog 
fi 
