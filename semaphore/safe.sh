#!/bin/bash

#"constants"
mindiff=84600 # if semaphore last mod < now-(some time mindiff, here 24 hrs) look to remove it.
curdatetime=$(date +%s)
cutoff=$((curdatetime-mindiff))

# error check exit conditions, something wrong
if [ ! -f /proc/sys/kernel/sem ]; then exit 1; fi;  max=$(cat /proc/sys/kernel/sem | awk '{print $4}'); max=1;
if [ ! -f /proc/sysvipc/sem ]; then exit 1; fi;  count=$(wc -l /proc/sysvipc/sem | awk '{print $1}')
if [ -z "$max" ] || [ -z "$count" ] || [ "$max" -lt "1" ] || [ "$count" -lt "1" ]; then exit 1; fi;
if [ -z "$curdatetime" ] || [ "$curdatetime" -lt "0" ]; then exit 1; fi
if [ -z "$cutoff" ] || [ "$cutoff" -lt "0" ]; then exit 1; fi

n=0 #track sems checked
d=0 #track sems recommended for del

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
    echo "sem=$semid pid=$pid optime=$optime, $(date -d @$optime)  ctime=$ctime, $(date -d @$ctime) "
    echo "checktime=$checktime, not in proc last heard from $(date -d @$checktime)"
    echo "---------"
    d=$((d+1))
  fi
  n=$((n+1))
done < /proc/sysvipc/sem
echo "Total sems=$n, $d recommend deleting"
