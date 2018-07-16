#!/bin/bash
set -x
DBSTR="linweb."$(date '+%Y-%m-%d-%H-%M-%S')".db"

sqlite3 "$DBSTR" < tbl.sql

#remove known hosts
rm -fr ~/.ssh/known_hosts
while read -r line
do
	
	#store result of remote command into local variable
	MYVAR=""
	MYVAR=$(./remote.ex "$1" "$line" "$2")

	#if response not null
	if [ -z "$MYVAR" ]
	then
		echo "issue with host $line - check" > out.log
	else

		echo "Good host $line"
		while read -r responseLine
		do
			#read local variabels from parsed response line
			sqlite3 "$DBSTR" "INSERT INTO checks(host,webspaceid) VALUES(\"$line\", \"$responseLine\");"
		done < <(echo "$MYVAR" |  sed -n '/\[andrewcu*/,/\[andrewcu*/p'| sed 1,2d|less | tac | sed 1,2d | tac)
	fi
done < <(cat source_ip_list)
