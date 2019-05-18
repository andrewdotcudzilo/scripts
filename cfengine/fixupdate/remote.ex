#!/usr/bin/expect -f
set pass [lrange $argv 0 0]
set server [lrange $argv 1 1]
set name [lrange $argv 2 2]
set prompt {$ }

spawn ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $name@$server 
#match_max 1000000
#set timeout 5
expect "?assword:*" { send "$pass\r" }
expect "$prompt" { send "sudo curl -s -k https://raw.githubusercontent.com/andrewdotcudzilo/scripts/master/cfengine/fixupdate/update.conf -o /var/cfengine/inputs/update.conf\r" }
expect "*andrewcu:*" { send "$pass\r" }
expect "$prompt" { send "sudo /usr/sbin/cfagent \r" }
expect "$prompt" { send "sudo /etc/init.d/zabbix-agent restart\r" }
puts $expect_out(buffer)
