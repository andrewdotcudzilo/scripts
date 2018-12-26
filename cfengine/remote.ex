#!/usr/bin/expect -f
set pass [lrange $argv 0 0]
set server [lrange $argv 1 1]
set name [lrange $argv 2 2]
set prompt {$ }

spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $name@$server 
#match_max 1000000
#set timeout 5
expect "?assword:*" { send "$pass\r" }
expect "$prompt" { send "curl -s -k https://raw.githubusercontent.com/andrewdotcudzilo/scripts/master/cfengine/check.sh | sudo bash\r" }

expect "*andrewcu:*" { send "$pass\r" }
expect "$prompt"
#sleep 15
expect "$prompt"
puts $expect_out(buffer)
