#!/bin/env bash

service_start(){
	systemctl start sshd &>/dev/null && echo -e "\033[32m Service sshd is running\033[0m"
}

service_stop(){
	systemctl stop sshd &>/dev/null && echo -e "\033[32m Service sshd is stopped\033[0m"
}

function service_disable(){
	systemctl disable sshd &>/dev/null && echo -e "\033[32m Service sshd is disabled\033[0m"
}

function service_restart(){
	systemctl restart sshd &>/dev/null && echo -e "\033[32m Service sshd is running\033[0m"
}

service_start
