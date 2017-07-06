#!/bin/bash

# iterate db looking for datetime field, order, and read each line
# take value of line, (skipping 1st run), and line previous
# those while be the conditionals for the query.
# this will get us a list of semids in table a/d that were NOT
# in table b/c -- the delta between two "runs".
# its hackish but I don't feel like writing a proper query

db="monitor.db"
lastdate=0
thisdate=0

sqlite3 "$db" "SELECT datetime FROM monitor WHERE id>1 GROUP BY datetime ORDER BY id ASC" | while read line
do
  thisdate="$line"

  if [ ! -z "$lastdate" ] && [ "$lastdate" != "0" ]
  then
    sqlite3 "$db" "
    SELECT a.* FROM monitor a WHERE a.datetime=\"$thisdate\" AND a.semid NOT IN(
     SELECT b.semid FROM (
      SELECT c.* FROM monitor c
       JOIN monitor d ON c.semid=d.semid AND d.datetime=\"$lastdate\"
      WHERE c.datetime=\"$thisdate\"
     ) b
    );"
  fi
  lastdate=$thisdate
done
