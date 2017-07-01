#!/bin/bash
# script that monitors semapphore usage; dumps to sqlite db on changes(increases)
# run this in a screen session will you?!
###
db="monitor.db"
sleep=20 #secs
max_db_size=1000 #megs=1g
### var inits
num_sem=0;
last_num_sem=0;
### lazy
if [ -f $db ]; then $(rm -fr ./"$db"); fi;
if [ ! -f $db ]; then sqlite3 "$db" < monitor.sql; fi;
db_size=$(du -m ./"$db" | cut -f 1) #get current db size;
### tell them weve started
echo "RUN: Started $(date) ---- "

## in our use case, size is a concern so loop until size (or user exit)
while [ $db_size -lt $max_db_size ]
do
  ## init vars of loop
  n=0
  thisIteration=$(date +"%Y-%m-%d %H:%M:%S")
  num_sem=$(wc -l < /proc/sysvipc/sem); num_sem=$((num_sem-1));   #-1 because first line is text header
  if [ -z "$num_sem"] || [ $num_sem -eq 0 ]; then continue; fi;   # cant get num_sem = skip iternation (maybe should exit 1)

  ## in our use case, we only want db capture when num_sem increase over time/interations
  if [ $last_num_sem -lt $num_sem];
  then
    echo "RUN: Semaphore change - was $last_num_sem now $num_sem - $(date)"
    while read -r line
    do
      if [ $n -eq 0 ]; then n=$((n+1)); continue; fi; #skip first line of file

      read semid optime ctime <<< $(echo "$line" | awk '{print $2, $9, $10}')
      if [ -z "$semid" ] || [ $semid -eq 0 ]; then n=$((n+1)); continue; fi; #null or owned by pid=0 stay away

      pid=$(ipcs -s -i "$semid" | awk 'FNR==9 {print $0}' | awk '{print $5}')
      if [ -z "$pid" ] || [ "$pid" -eq "0" ]; then n=$((n+1)); continue; fi; #null or pid=0 stay away

      if [ -d /proc/"$pid" ];
      then
        cmd=$(cat /proc/"$pid"/cmdline)
        in_proc="Y"
      else
        cmd=null
        in_proc="N"
      fi;

      sqlite3 monitor.db "INSERT INTO monitor(semid, otime, ctime, pid, in_proc, cmd, datetime) VALUES ($semid, $optime, $ctime, $pid, \"$in_proc\", \"$cmd\", \"$thisIteration\")"
      #echo "INSERT INTO monitor(semid, otime, ctime, pid, in_proc, cmd, datetime) VALUES ($semid, $optime, $ctime, $pid, $in_proc, $cmd, $thisIteration)"
      n=$((n+1))
    done < /proc/sysvipc/sem
  fi

  last_num_sem=$((num_sem)) #cast
  sleep "$sleep"  #we can sleep for less as we technically or just tracking increases, theres more processing, but less data-capture.
  db_size=$(du -m ./"$db" | cut -f 1)
done
