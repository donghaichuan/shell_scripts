#!/usr/bin/env expect
# 启动一个程序
spawn ssh root@192.168.0.108
# 捕获相关内容
expect {
	"(yes/no)?" { send "yes\r";exp_continue }
	"password:" { send "qwer1234\r" }
}
#interact
