#!/bin/bash

# recommend running this is a screen session in case
# of disconnects

db="monitor.db"
sleep=60
max_db_size=1000 #megs=1g
cur_db_size=$(du -m ./"$db"|cut -f 1)

if [ ! -f $db ]
then
  sqlite3 "$db" < monitor.sql
fi

thisIteration=1

while [ 1 ]
do
  n=0
  while read -r line
  do
    if [ $n -eq 0 ]; then n=$((n+1)); continue; fi; #skip first line of file

    read semid optime ctime <<< $(echo "$line" | awk '{print $2, $9, $10}')
    if [ -z "$semid" ] || [ "$semid" -eq "0" ]; then n=$((n+1)); continue; fi; #null or owned by pid=0 stay away

    pid=$(ipcs -s -i "$semid" | awk 'FNR==9 {print $0}' | awk '{print $5}')
    if [ -z "$pid" ] || [ "$pid" -eq "0" ]; then n=$((n+1)); continue; fi; #null or pid=0 stay away

    if [ -d /proc/"$pid"];
    then
      cmd=$(cat /proc/"$pid"/cmdline)
      in_proc="Y"
    else
      cmd=null
      in_proc="N"
    fi;

    echo "INSERT INTO monitor(semid, otime, ctime, pid, in_proc, cmd, iteration) VALUES ($semid, $otime, $ctime, $pid, $in_proc, $cmd, $thisIteration)"
    n=$((n+1))
  done <<< /proc/sysvipc/sem
  thisIteration=$((thisIteration+1))
done
