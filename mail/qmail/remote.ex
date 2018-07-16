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
expect "$prompt" { send "sudo /var/qmail/bin/qmail-qstat\r" }
expect "?assword:*" { send "$pass\r" }
expect "$prompt" { send "curl -s -k https://raw.githubusercontent.com/andrewdotcudzilo/scripts/master/mail/qmail/lazy.sh | sudo bash\r" }
expect "$prompt" { send "sudo /etc/init.d/qmail restart\r" } 
expect "$prompt" { send "sudo /var/qmail/bin/qmail-qstat\r" }
expect "$prompt"
exit

