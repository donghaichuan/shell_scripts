#! /bin/bash

export LANG="en_US.UTF-8"

function green(){
    printf "\033[1;32m$1\033[0m\n"
}

function red(){
    printf "\033[1;31m$1\033[0m\n"
}

function blue(){
    printf "\033[1;34m$1\033[0m\n"
}

# 检查是否传入了参数
if [ $# -ne 1 ]; then
    green "脚本执行有且只有一个参数，即指定ansible容器挂载的宿主机目录路径。建议使用绝对路径！"
    red "Usage: $0 容器挂载目录路径 "
    exit 1
fi


docker_dir=$1


tmp_dir=/tmp/installDocker
if [ -d $tmp_dir ]
then
    rm -rf $tmp_dir
fi

mkdir -p $tmp_dir >/dev/null
if [ $? -ne 0 ]
then
    red "Error: prepare env error, failed create tmp dir..." >&2
    rm -rf $tmp_dir
    exit 1
fi

ARCHIVE=`awk '/^__ARCHIVE_BELOW__/ {print NR + 1; exit 0; }' "$0"`
tail -n+$ARCHIVE "$0" | tar -ixzvm -C $tmp_dir > /dev/null 2>&1 3>&1
if [ $? -ne 0 ]
then
    red "Error: prepare env error, failed create extract files..." >&2
    rm -rf $tmp_dir
    exit 1
fi

cd $tmp_dir
cd docker_install
cpu_type=`uname -m`

if [ $cpu_type == 'x86_64' ]; then
    tar xf docker-x86_64-20.10.21.tgz
    rm -f docker-x86_64-20.10.21.tgz
    rm -f docker-aarch64-20.10.21.tgz
elif [ $cpu_type == 'aarch64' ]; then
    tar xf docker-aarch64-20.10.21.tgz
    rm -f docker-x86_64-20.10.21.tgz
    rm -f docker-aarch64-20.10.21.tgz
else
    red "当前支持的处理器类型为x86_64、aarch64。您的处理器类型为$cpu_type"
    exit 1
fi

if [ -f /usr/bin/dockerd ]; then
    green "docker已安装，无需重复安装!"
else
    mv docker/* /usr/bin/
fi


egrep docker /etc/group > /dev/null 2>&1 
if [ $? -ne 0 ]; then
    groupadd docker
fi

ps -ef|egrep dockerd|egrep -v "grep" > /dev/null 2>&1 
if [ $? -eq 0 ]; then
    green "docker服务运行中，无需重启服务!"
else
    /usr/bin/cp docker.service /usr/lib/systemd/system/docker.service
    /usr/bin/cp containerd.service /usr/lib/systemd/system/containerd.service
    /usr/bin/cp docker.socket /usr/lib/systemd/system/docker.socket
    systemctl unmask docker.service 
    systemctl unmask docker.socket
    systemctl unmask containerd.service
    systemctl daemon-reload
    systemctl start docker.service
fi

docker load -i ansible-${cpu_type}-v2.9.6.tar.gz > /dev/null 2>&1 
rm -rf $tmp_dir

mkdir -p ${docker_dir} > /dev/null 2>&1 
docker ps -a |awk '{print $NF}'|egrep ansible > /dev/null 2>&1 
if [ $? -eq 0 ]; then
    green "已经存在名为ansible的容器，不执行容器启动或重启操作！"
    exit 0
else
    docker run --name ansible -d -v ${docker_dir}:/data ansible_ubuntu:v2.9.6 > /dev/null 2>&1 
    if [ $? -eq 0 ]; then
        green "ansibe容器启动成功！"
        green "${docker_dir}目录已经被挂载到容器中的/data，请将使用的文件拷贝到${docker_dir}目下，然后使用下面的命令登录到容器中执行部署操作："
        blue "docker exec -it ansible bash"
        exit 0
    else
        red "ansible容器启动失败!"
        exit 1
    fi
fi

exit 0

__ARCHIVE_BELOW__
