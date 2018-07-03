#!/bin/bash
#set -x
DBSTR="check."$(date '+%Y-%m-%d-%H-%M-%S')".db"
re='^[0-9]+$'
re2='^-*$'

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
		A=B=C=D=E=F=""
		echo "Good host $line"
		while read -r responseLine
		do
			#read local variabels from parsed response lines
			read A B C D E F <<< $(echo "$responseLine" | awk '{print $1,$2,$3,$4,$5,$6}')
			if ! [[ $B =~ $re ]]; then B=0; fi;
			F=0;
			sqlite3 "$DBSTR" "INSERT INTO checks(host,ctid,nproc,ctstatus,ctip,cthostname,ctdiskspace) VALUES(\"$line\",$A,$B,\"$C\",\"$D\",\"$E\",$F);"
		done < <(echo "$MYVAR" | tac | sed '/\[andrewcu/,$!d;/CTID/q' | tac | awk 'NR>3 ' | sed '$ d')
	fi
done < <(cat source_ip_list)
