#!/bin/bash
#set -x

#remove known hosts
rm -fr ~/.ssh/known_hosts
while read -r line
do
	IFS=',' read a b <<< "$line"

#	DEFAULT="ERROR";
./remote.ex "$1" "$a" "$2"
#	LOGOUT=""
#	if [ -z "${REMOTE}" ]
#	then
#		LOGOUT="$DEFAULT";
#	else
#		LOGOUT=$(echo "${REMOTE}" | awk '/Searching for installed licenses/{flag=1;next}/andrewcu@/{flag=0}flag')
#	fi

done < <(cat source_rvzlin.list)
