#!/usr/bin/expect -f
set pass [lrange $argv 0 0]
set server [lrange $argv 1 1]
set name [lrange $argv 2 2]
set prompt {$ }

spawn ssh  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $name@$server 
#match_max 1000000
#set timeout 5
expect "?assword:*" { send "$pass\r" }
expect "$prompt" { send "sudo exim -bpc\r" }
expect "?assword:*" { send "$pass\r" }
set timeout -1
expect "$prompt" { send "curl -s -k https://raw.githubusercontent.com/andrewdotcudzilo/scripts/master/mail/exim/exim_clean.sh | sudo bash\r" }
sleep 10
expect "$prompt"
exit

