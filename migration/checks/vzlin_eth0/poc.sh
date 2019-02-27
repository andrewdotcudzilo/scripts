#!/bin/bash
#set -x

#remove known hosts
rm -fr ~/.ssh/known_hosts
while read -r line
do
	IFS=',' read a b <<< "$line"

	REMOTE="$(./remote.ex "$1" "$a" "$2")"
        echo -e "----\n $REMOTE \n\n" | tee -a dump.log
done < <( cat source_ip_list.orig )
