#!/usr/bin/expect -f
set pass [lrange $argv 0 0]
set server [lrange $argv 1 1]
set name [lrange $argv 2 2]
set prompt {$ }

spawn ssh  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $name@$server 
#match_max 1000000
#set timeout 5
expect "?assword:*" { send "$pass\r" }
expect "$prompt" { send "sudo cfagent --no-splay\r" }
expect "?assword:*" { send "$pass\r" }
set timeout -1
sleep 10
expect "$prompt"
exit

