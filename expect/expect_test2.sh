#!/usr/bin/env expect
set user root
set ip 192.168.0.108
set pass qwer1234
# 启动一个程序
spawn ssh $user@$ip
# 捕获相关内容
expect {
        "(yes/no)?" { send "yes\r";exp_continue }
        "password:" { send "$pass\r" }
}
interact
