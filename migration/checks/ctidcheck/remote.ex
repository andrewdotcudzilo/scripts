#!/usr/bin/expect -f
set pass [lrange $argv 0 0]
set server [lrange $argv 1 1]
set name [lrange $argv 2 2]
set prompt {$ }

spawn ssh $name@$server 
#match_max 1000000
#set timeout 5
expect "*?re" { send "yes\r" }
expect "?assword:*" { send "$pass\r" }
sleep 10
expect "$prompt" { send "sudo /usr/sbin/vzlist -a -o ctid,numproc,status,ip,hostname,diskspace\r" }
expect "*andrewcu:*" { send "$pass\r" }
expect "$prompt"
expect "$prompt"
puts $expect_out(buffer)
