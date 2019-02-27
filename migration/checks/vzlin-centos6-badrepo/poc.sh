#!/bin/bash
#set -x

#remove known hosts
rm -fr ~/.ssh/known_hosts
while read -r line
do
	IFS=',' read a b <<< "$line"

	REMOTE="$(./remote.ex "$1" "$a" "$2")"
	TEST=$(echo "$REMOTE" | tail -n 10)
        echo "$b - $a - ${TEST}" | tee -a out.log
	echo "" | tee -a out.log
        echo "" | tee -a out.log	
done < <(cat source_ip_list.orig)
