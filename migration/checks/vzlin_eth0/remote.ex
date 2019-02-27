#!/usr/bin/expect -f
set pass [lrange $argv 0 0]
set server [lrange $argv 1 1]
set name [lrange $argv 2 2]
set prompt {$ }

spawn ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $name@$server
#match_max 1000000
#set timeout 5
#expect "*?re" { send "yes\r" }
expect "?assword:*" { send "$pass\r" }

expect "$prompt" { send "sudo /sbin/ifconfig | grep eth -A 1 | awk '{print \$2}' \r"}
expect "*andrewcu:*" { send "$pass\r" }
expect "$prompt"
#puts $expect_out(buffer) 
