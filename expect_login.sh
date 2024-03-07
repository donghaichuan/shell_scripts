#!/usr/bin/expect

set timeout 3
set username [lindex $argv 0]
set ip [lindex $argv 1]
set password [lindex $argv 2]
spawn ssh -l $username $ip 

expect {
    "yes/no" {send "yes\r";exp_continue}
    "*password*" {send "$password\r";}
}

expect eof
#interact