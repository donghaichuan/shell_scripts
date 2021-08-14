#!/bin/env bash
read -p "Please input your service name(sshd):" service_name
case $service_name in
	sshd)
	case $1 in
		start)
		systemctl start sshd
		sshd_state=`ps -ef |grep sshd |grep -v grep`
			if [  "$sshd_state" != " " ];then 
			echo -e "\033[32mService sshd is running\033[0m"
			else
			echo -e "\033[31mPlease check sshd service state\033[0m"
			fi
		;;
		-h|--help)
		echo "this is usage"
		;;
		
		*)
		echo "-h or --help, get help for this script"
		;;
	esac
	;;
	
	*)
	echo -e "\033[31mPlease input correct service name\033[0m"
	;;
esac
