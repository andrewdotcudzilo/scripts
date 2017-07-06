#!/bin/bash
# script that monitors semapphore usage; dumps to sqlite db on increases
db="monitor.db"
semfile="/proc/sysvipc/sem"
sleep=20 #secs
max_db_size=1000 #megs=1g
cur_num_sem=0;
last_run_sem=0;

if [ -f $db ]; then $(rm -fr ./"$db"); fi;
if [ ! -f $db ]; then sqlite3 "$db" < monitor.sql; fi;
db_size=$(du -m ./"$db" | cut -f 1) #get current db size;

echo "RUN: Started $(date) ---- "
while [ $db_size -lt $max_db_size ]
do
  ln=0 #line number on /proc/sysvipc/sem we are on
  datetime=$(date +"%Y-%m-%d %H:%M:%S") #datetime in iso format
  cur_num_sem=$(wc -l < "$semfile"); cur_num_sem=$((cur_num_sem-1)); #true val of sems, first line is header

  if [ -z "$cur_num_sem" ] || [ $cur_num_sem -le 0 ]; then continue; fi;  #no sems, skip interations
  if [ $last_run_sem -lt $cur_num_sem ] #cur sems > last interations
  then
    echo "RUN: Semaphore change.  Was: $last_run_sem Now: $cur_num_sem - $(date)";
    while read -r line
    do
      if [ $n -eq 0 ]; then ln=$((ln+1)); continue; fi; #skip first line of file - its headres

      read semid optime ctime <<< $(echo "$line" | awk '{print $2, $9, $10}')
      if [ -z "$semid" ] || [ $semid -eq 0 ]; then ln=$((ln+1)); continue; fi; #null or owned by pid=0 stay away
      pid=$(ipcs -s -i "$semid" | awk 'FNR==9 {print $0}' | awk '{print $5}')
      if [ -z "$pid" ] || [ "$pid" -eq "0" ]; then ln=$((ln+1)); continue; fi; #null or pid=0 stay away

      if [ -d /proc/"$pid" ] #clean this up sometime
      then
        cmd=$(cat /proc/"$pid"/cmdline)
        in_proc="Y"
      else
        cmd=null
        in_proc="N"
      fi
      #
      sqlite3 monitor.db "INSERT INTO monitor(semid, otime, ctime, pid, in_proc, cmd, datetime) VALUES ($semid, $optime, $ctime, $pid, \"$in_proc\", \"$cmd\", \"$datetime\")"
      #echo "INSERT INTO monitor(semid, otime, ctime, pid, in_proc, cmd, datetime) VALUES ($semid, $optime, $ctime, $pid, $in_proc, $cmd, $thisIteration)"
      ln=$((ln+1)) #increase l
    done < "$semfile"
  fi
  last_run_sem=$((cur_num_sem) #cast
  sleep "$sleep"  #we can sleep for less as we technically or just tracking increases, theres more processing, but less data-capture.
  db_size=$(du -m ./"$db" | cut -f 1)
done
