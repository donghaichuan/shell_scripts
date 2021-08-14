#!/bin/env bash

# 脚本的使用帮助手册
function usage(){
	cat <<EOF
Usage:
	-h or --help	get help information
	-l or list	get all packages information
	-a or add	add centos7 repo
	-c or check	check package is not installed
	-i or install	install package
	-r or remove	remove package
	-d or download	download package
EOF
}

# 输出脚本支持安装的软件有哪些
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

# 添加centos的yum源
function add_centos7_repo(){
	mkdir -p /etc/yum.repos.d/repo_bak
	mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/repo_bak/
	# 添加base源
	wget -O /etc/yum.repos.d/CentOS-7-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
	# 添加epel源
	wget -O /etc/yum.repos.d/CentOS-7-epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
	yum clean all && yum makecache fast &>/dev/null
	echo -e "\n"
	echo -e "\033[32m###################可用repo源如下#######################\033[0m"
	yum repolist
}

# 判断用户输入的软件包名为空值
function no_packages_name(){
	if [ -z "$package_name" ];then
                echo -e "\033[31m Please input your package name\033[0m"
                exit
	fi
}

# 检查用户输入的软件包是否已经安装
function packages_check(){
	read -p "Please input package name(httpd,vsftpd,nfs,ntp,nginx):" package_name
	no_packages_name
	pkg_name=`rpm -qa |grep -w $package_name`
	if [ -z "$pkg_name" ];then
        	echo -e "\033[32m Package $package_name is not installed\033[0m"
	else
        	echo -e "\033[32m Package $package_name is already installed\033[0m"
	fi
}

# 安装用户输入的软件包
function packages_install(){
	read -p "Please input package name(httpd,vsftpd,nfs):" package_name
	no_packages_name
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
		echo -e "\033[31mPackage $package_name not found\033[0m"
		exit 1
	esac
	if [ $? == 0 ];then 
		echo -e "\033[32m Package $package_name is installed,Please check $package_name service is running.\033[0m"
	fi
}

# 删除用户输入的软件包
function packages_remove(){
        read -p "Please input package name(httpd,vsftpd,nfs):" package_name
	no_packages_name
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
		ntp)
		yum remove ntp ntpdate -y
		;;
		nginx)
		yum install nginx -y
		;;
                *)
                echo -e "Package $package_name not found"
        esac
	echo -e "\033[32m Package $package_name is removed.\033[0m"
}

# 下载用户输入的软件包及其依赖包
function packages_download(){
	read -p "Please input package name(httpd,vsftpd,nfs):" package_name
	no_packages_name
        yum install yum-plugin-downloadonly -y &>/dev/null
	case $package_name in
                httpd|http)
		yum install --downloadonly --downloaddir=$(pwd)/packages/$package_name httpd &>/dev/null
		;;
                ftp|vsftpd)
		yum install --downloadonly --downloaddir=$(pwd)/packages/$package_name vsftpd &>/dev/null
		;;
                nfs)
		yum install --downloadonly --downloaddir=$(pwd)/packages/$package_name nfs-utils rpcbind &>/dev/null
		;;
                ntp)
		yum install --downloadonly --downloaddir=$(pwd)/packages/$package_name ntp ntpdate &>/dev/null
		;;
                nginx)
		yum install --downloadonly --downloaddir=$(pwd)/packages/$package_name nginx &>/dev/null
		if [ $? != 0 ];then
		echo -e "\033[31m Package $package_name not found\033[0m"
		exit 0
		fi
		;;
		*)
	esac
	echo -e "\033[32m Package $package_name is download to $(pwd)/packages/$package_name\033[0m "
}

# 默认执行的入口脚本
function packages(){
	case $1 in
		-h|--help)
		usage
		;;
		-a|add)
		add_centos7_repo
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
		-d|download)
		packages_download
		;;
		*)
		usage
		;;
	esac
}

# 启动本脚本
packages $1
