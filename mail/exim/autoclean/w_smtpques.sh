#!/bin/bash

str_out=""
for server in $(cat source_ip_list);
do
	tmp=$(echo -n "$server -")
	str_out="$str_out $tmp"
	tmp=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR root@$server exim -bpc);
	str_out="$str_out $tmp"
	tmp=$(ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=Error root@$server netstat -an|awk '{print $4}'|grep ":25"| wc -l)
	str_out="$str_out $tmp"
	echo $str_out;
	str_out="";
done;

