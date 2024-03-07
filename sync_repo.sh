#!/bin/bash

# 设置变量
REPO_PATH=/mnt/repo # 定义服务端文件存放路径
CENTOS7_VERSION=7.9 # 定义centos版本
CENTOS7_IMAGE=centos7.9.2009 # 定义centos7镜像
UBUNTU_VERSIN=20.04
UBUNTU_IMAGE=ubuntu:20.04

# 定义CPU架构
cpu_type() {
    if [ $(uname -m) = "x86_64" ]; then
        export CPU_TYPE=x86_64
    elif [ $(uname -m) = "aarch64" ]; then
        export CPU_TYPE=arm64
    else
        error The system arch is not supported
    fi
}

# 启动centos7.9容器
run_centos7_container(){
    docker rm -f centos7.9 && docker run -it -d -v $REPO_PATH:/mnt $CENTOS7_IMAGE centos7.9
}

# 同步centos7.9源
sync_centos7_repo(){
    cpu_type
    tee /tmp/sync_centos.sh >/dev/null <<EOF
#!/bin/bash
mkdir -p /mnt/centos/$CENTOS7_VERSION/$CPU_TYPE
export CENTOS_PATH=/mnt/centos/$CENTOS7_VERSION/$CPU_TYPE
cd $CENTOS_PATH
yum makecache && yum install wget -y && rm -rf /etc/yum.repos.d/*.repo
wget -O /etc/yum.repos.d/CentOS-7.repo http://mirrors.aliyun.com/repo/Centos-7.repo 
yum clean all && yum makecache
echo 'Syncing base repo' 
export DATETIME=`date +%F_%T` 
exec > /var/log/aliyumrepo_$DATETIME.log 
reposync -g -l -d -m --download-metadata --newest-only
if [ $? -eq 0 ];then
    createrepo --update $CENTOS_PATH/base
    createrepo --update $CENTOS_PATH/extras
    createrepo --update $CENTOS_PATH/updates
    
    echo "SUCESS: $DATETIME aliyum_yum update successful" >>/var/log/aliyumrepo_$DATETIME.log
else
    echo "ERROR: $DATETIME aliyum_yum update failed" >> /var/log/aliyumrepo_$DATETIME.log
fi
EOF
    chmod +x /tmp/sync_centos.sh
    docker cp /tmp/sync_centos.sh centos7.9:/mnt &&
    docker exec -i centos7.9 /bin/bash -c "/mnt/sync_centos.sh"
}

sync_epel7_repo(){
    cpu_type
    tee /tmp/sync_epel.sh >/dev/null <<EOF
#!/bin/bash
mkdir -p /mnt/epel/$CENTOS7_VERSION/$CPU_TYPE
export EPEL_PATH=/mnt/epel/$CENTOS7_VERSION/$CPU_TYPE
cd $EPEL_PATH
yum makecache && yum install wget -y && rm -rf /etc/yum.repos.d/*.repo
wget -O /etc/yum.repos.d/epel-7.repo http://mirrors.aliyun.com/repo/epel-7.repo 
yum clean all && yum makecache
echo 'Syncing epel repo' 
export DATETIME=`date +%F_%T` 
exec > /var/log/aliyumrepo_$DATETIME.log 
reposync -g -l -d -m --download-metadata --newest-only
if [ $? -eq 0 ];then
    createrepo --update $EPEL_PATH/epel

    echo "SUCESS: $DATETIME aliyum_yum update successful" >>/var/log/aliyumrepo_$DATETIME.log
else
    echo "ERROR: $DATETIME aliyum_yum update failed" >> /var/log/aliyumrepo_$DATETIME.log
fi
EOF
    chmod +x /tmp/sync_epel.sh
    docker cp /tmp/sync_epel.sh centos7.9:/mnt &&
    docker exec -i centos7.9 /bin/bash -c "/mnt/sync_epel.sh"
}

main(){
    run_centos7_container
    sync_centos7_repo
    sync_epel7_repo
}

main
