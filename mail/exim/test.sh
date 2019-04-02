#!/usr/bin/expect -f
set timeout 20

set ip [lindex $argv 0]

spawn telnet "$ip" 25
expect "220*" { send "helo mail.com\r" }
expect "250 " { send "mail from: mhtest@throwthings.com\r" }
expect "250 ok" { send "rcpt to: andrew.cudzilo@hostwaycorp.com\r" }
expect "250 ok" { send "quit\r" }
expect "221*" { send "quit\r" } 
exit

