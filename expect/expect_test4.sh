#!/usr/bin/env expect
set user [ lindex $argv 0 ]
set ip [ lindex $argv 1 ]
set pass [ lindex $argv 2]
# 启动一个程序
spawn ssh $user@$ip
# 捕获相关内容
expect {
        "(yes/no)?" { send "yes\r";exp_continue }
        "password:" { send "$pass\r" }
}
interact
