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

expect "$prompt" { send "sudo /usr/sbin/vzlicview\r"}
expect "*andrewcu:*" { send "$pass\r" }
expect "$prompt"
#puts $expect_out(buffer) 
