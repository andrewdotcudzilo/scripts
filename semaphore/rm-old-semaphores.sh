#!/bin/bash
# andrewcu@softcom.com
# HEY - THIS WILL DELETE STUFF BE CAREFUL

### constants
LOGFILE=/var/local/rm-old-semaphores-$(date +%Y_%m_%d_%H_%M_%S).log
MINDIFF=$((84600*2)) # if semaphore last mod < now-(some time mindiff, here 48 hrs) look to remove it. (made cut off 2 days)
CURDATETIME=$(date +%s)
CUTOFF=$((curdatetime-mindiff))
### VARIABLES
n=0 #track sems checked
d=0 #track sems deleted

# error check exit conditions, something wrong
if [ ! -f /proc/sys/kernel/sem ]; then exit 1; fi;  MAX=$(cat /proc/sys/kernel/sem | awk '{print $4}');
if [ ! -f /proc/sysvipc/sem ]; then exit 1; fi;  COUNT=$(wc -l /proc/sysvipc/sem | awk '{print $1}')
if [ -z "$MAX" ] || [ -z "$COUNT" ] || [ "$MAX" -lt "1" ] || [ "$COUNT" -lt "1" ]; then exit 1; fi;
if [ -z "$CURDATETIME" ] || [ "$CURDATETIME" -lt "0" ]; then exit 1; fi
if [ -z "$CUTOFF" ] || [ "$CUTOFF" -lt "0" ]; then exit 1; fi


if [ ! -f "$LOGFILE" ]; then touch "$LOGFILE"; fi;
echo "Start: Semaphore cleanup script execution $(date):" >> $LOGFILE

# if we encounter bad/unexpected/0 value we typically skip semaphore/pid/etc
while read -r line
do
  if [ "$n" -le "0" ]; then n=$((n+1)); continue; fi; #skip first line -- text header

  read SEMID OPTIME CTIME <<< $(echo "$line" | awk '{print $2, $9, $10}')
  if [ -z "$SEMID" ] || [ "$SEMID" -eq "0" ]; then n=$((n+1)); continue; fi; #null or owned by pid=0 stay away

  PID=$(ipcs -s -i "$SEMID" | awk 'FNR==9 {print $0}' | awk '{print $5}')
  if [ -z "$PID" ] || [ "$PID" -eq "0" ]; then n=$((n+1)); continue; fi; #null or pid=0 stay away

  if [ -d /proc/"$PID" ]; then n=$((n+1)); continue; fi;

  if [ $OPTIME -gt 0 ]; then checktime=$OPTIME; else checktime=$CTIME; fi; #get most recent 'modification'
  if [ -z "$checktime" ] || [ "$checktime" -eq "0" ]; then n=$((n+1)); continue; fi;

  if [ $checktime -le $CUTOFF ]
  then
    echo "semId=$SEMID PID=$PID - not found in /proc, last heard from at $(date -d @$checktime) will be removed." >> $LOGFILE
    #ipcrm -s "$SEMID" #uncomment this line to actually remove semaphores
    #d=$((d+1))
  fi
  n=$((n+1))
done < /proc/sysvipc/sem
n=$((n-1))
echo "End: System semaphores=$n, and $d semaphores were deleted because there was no /proc reference to the PID and last mod time was >= $((MINDIFF/60/60)) hours ago" >> $LOGFILE

if [ "$d" -gt "0" ]
then
  /etc/init.d/zabbix-agent restart
  srvadmin-services.sh restart
fi
