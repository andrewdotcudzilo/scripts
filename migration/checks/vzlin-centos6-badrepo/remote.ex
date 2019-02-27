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

expect "$prompt" { send "hostname\r"}
expect "$prompt" { send "cat /etc/redhat-release\r" }
expect "$prompt" { send "cat /vz/template/centos/6/x86_64/config/os/default/repositories\r"}
expect "$prompt" { send "logout\r" } 
puts $expect_out(buffer) 
