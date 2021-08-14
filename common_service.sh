#!/bin/env bash

# 脚本默认的帮助手册
function usage(){
	cat <<EOF
Usage:
	-h or --help	get help information
	-l or list	get all packages information
	-c or check	check package is not installed
	-i or install	install package
	-r or remove	remove package
EOF
}

# 查看脚本支持的软件包
function packages_list(){
	cat <<EOF
Usage:
	httpd	package http is supported
	vsftpd	package ftp is supported
	nfs	package nfs is supported
	ntp	package ntp is supported
	nginx	package nginx is supported
EOF
}

# 检查软件包是否已安装
function packages_check(){
	read -p "Please input package name(httpd,vsftpd,nfs):" package_name
	pkg_name=`rpm -qa |grep $package_name`
	if [ -z "$pkg_name" ];then
		echo "Package $package_name is not installed"
	else
		echo "Package $package_name is already installed"
	fi
}

# 安装软件包
function packages_install(){
	read -p "Please input package name(httpd,vsftpd,nfs):" package_name
	case $package_name in
		httpd)
		yum install httpd -y
		;;
		vsftpd)
		yum install vsftpd -y
		;;
		nfs)
		yum install nfs-utils rpcbind -y
		;;
		ntp)
		yum install ntp ntpdate -y
		;;
		nginx)
		yum install nginx -y
		;;
		*)
		echo -e "Package $package_name not found"
	esac
	echo -e "\033[32m Package $package_name is installed,Please check $package_name service is running.\033[0m"
}

# 卸载软件包
function packages_remove(){
        read -p "Please input package name(http,ftp,nfs):" package_name
        case $package_name in
                httpd|http)
                yum remove httpd -y
                ;;
                ftp|vsftpd)
                yum remove vsftpd -y
                ;;
                nfs)
                yum remove nfs-utils rpcbind -y
                ;;
                *)
                echo -e "Package $package_name not found"
        esac
	echo -e "\033[32m Package $package_name is removed.\033[0m"
}

# 脚本的主函数
function packages(){
	case $1 in
		-h|--help)
		usage
		;;
		-l|list)
		packages_list
		;;
		-c|check)
		packages_check
		;;
		-i|install)
		packages_install
		;;
		-r|remove)
		packages_remove
		;;
		*)
		usage
		;;
	esac
}

# 调用主函数，并在脚本后添加一个参数
packages $1
