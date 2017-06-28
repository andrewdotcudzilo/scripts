#!/bin/bash
# hey, this will actually remove semaphores, so use with caution
# hey2, this needs root privs for execution
logfile=/var/local/clean_semaphores_$(date +%Y_%m_%d_%H_%M_%S).log

#"constants"
mindiff=84600 # if semaphore last mod < now-(some time mindiff, here 24 hrs) look to remove it.
curdatetime=$(date +%s)
cutoff=$((curdatetime-mindiff))

# error check exit conditions, something wrong
if [ ! -f /proc/sys/kernel/sem ]; then exit 1; fi;  max=$(cat /proc/sys/kernel/sem | awk '{print $4}');
if [ ! -f /proc/sysvipc/sem ]; then exit 1; fi;  count=$(wc -l /proc/sysvipc/sem | awk '{print $1}')
if [ -z "$max" ] || [ -z "$count" ] || [ "$max" -lt "1" ] || [ "$count" -lt "1" ]; then exit 1; fi;
if [ -z "$curdatetime" ] || [ "$curdatetime" -lt "0" ]; then exit 1; fi
if [ -z "$cutoff" ] || [ "$cutoff" -lt "0" ]; then exit 1; fi

n=0 #track sems checked
d=0 #track sems deleted

if [ ! -f "$logfile" ]; then touch "$logfile"; fi;
echo "Semaphore cleanup script execution $(date):" >> $logfile

# if we encounter bad/unexpected/0 value we typically skip semaphore/pid/etc
while read -r line
do
  if [ "$n" -le "0" ]; then n=$((n+1)); continue; fi; #skip first line -- text header

  read semid optime ctime <<< $(echo "$line" | awk '{print $2, $9, $10}')
  if [ -z "$semid" ] || [ "$semid" -eq "0" ]; then n=$((n+1)); continue; fi; #null or owned by pid=0 stay away

  pid=$(ipcs -s -i "$semid" | awk 'FNR==9 {print $0}' | awk '{print $5}')
  if [ -z "$pid" ] || [ "$pid" -eq "0" ]; then n=$((n+1)); continue; fi; #null or pid=0 stay away

  if [ -d /proc/"$pid" ]; then n=$((n+1)); continue; fi;

  if [ $optime -gt 0 ]; then checktime=$optime; else checktime=$ctime; fi; #get most recent 'modification'
  if [ -z "$checktime" ] || [ "$checktime" -eq "0" ]; then n=$((n+1)); continue; fi;

  if [ $checktime -le $cutoff ]
  then
    echo "semId=$semid PID=$pid - not found in /proc, last heard from at $(date -d @$checkdate) will be removed." >> $logfile
    d=$((d+1))
  fi
  n=$((n+1))
done < /proc/sysvipc/sem
n=$((n--))
echo "System semaphores=$n, and $d semaphores were deleted because there was no /proc reference to the PID and last mod time was >= 24hrs ago" >> $logfile
