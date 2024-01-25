#! /bin/bash

# 准备ansible，nfs，docker，docker-compose，k8s，k3s，k9s，helm。。。离线包
# set -e
set -x
set -o noglob

# 定义常量
LOCAL_PATH=/path
DL_SERVER=dl.tsingj.local/offline_install
RSYNC_SERVER=rsync.tsingj.local::offline_install
K3S_VERSION=v1.27.5
K3S_GITHUB=https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION%2Bk3s1
K9S_VERSION=v0.31.7
HELM_VERSION=v3.12.3

# 定义日志类型
info() {
    printf "\033[1;32m[INFO]:$1\033[0m\n"
}
warn() {
    printf "\033[1;36m[WARN]:$1\033[0m\n"
}
error() {
    printf "\033[1;31m[ERROR]:$1\033[0m\n"
    exit 1
}

# 创建本地路径
create_local_path(){
    mkdir -p $LOCAL_PATH
}

# 配置github静态解析
update_hosts() {
    sed -i "/github*/d" /etc/hosts
    cat >>/etc/hosts <<EOF
140.82.114.4    github.com
199.232.5.194   github.global.ssl.fastly.net
EOF
}

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

# 添加yum源
add_yum_repo() {
    cpu_type
    mkdir -p /tmp/yum.repos.d
    tee /tmp/yum.repos.d/epel-7.repo >/dev/null <<EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - $(uname -m)
baseurl=http://mirrors.aliyun.com/epel/7/$(uname -m)
failovermethod=priority
enabled=1
gpgcheck=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $(uname -m) - Debug
baseurl=http://mirrors.aliyun.com/epel/7/$(uname -m)/debug
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=0

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $(uname -m) - Source
baseurl=http://mirrors.aliyun.com/epel/7/SRPMS
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=0
EOF
    if [ "$CPU_TYPE" = "x86_64" ]; then
        tee /tmp/yum.repos.d/base-7.repo >/dev/null <<EOF
[base]
name=CentOS-7.9.2009 - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7.9.2009/os/$(uname -m)/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-7.9.2009 - Updates - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7.9.2009/updates/$(uname -m)/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-7.9.2009 - Extras - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7.9.2009/extras/$(uname -m)/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-7.9.2009 - Plus - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7.9.2009/centosplus/$(uname -m)/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#contrib - packages by Centos Users
[contrib]
name=CentOS-7.9.2009 - Contrib - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/7.9.2009/contrib/$(uname -m)/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
EOF
    else
        tee /tmp/yum.repos.d/base-7.repo >/dev/null <<EOF
[base]
name=CentOS-7.9.2009 - Base
baseurl=http://mirrors.aliyun.com/centos-altarch/7.9.2009/os/$(uname -m)/
gpgcheck=0
gpgkey=http://mirrors.aliyun.com/centos-altarch/7/os/$(uname -m)/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-7.9.2009 - Updates
baseurl=http://mirrors.aliyun.com/centos-altarch/7.9.2009/updates/$(uname -m)/
gpgcheck=0
gpgkey=http://mirrors.aliyun.com/centos-altarch/7/os/$(uname -m)/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-7.9.2009 - Extras
baseurl=http://mirrors.aliyun.com/centos-altarch/7.9.2009/extras/$(uname -m)/
gpgcheck=0
gpgkey=http://mirrors.aliyun.com/centos-altarch/7/os/$(uname -m)/RPM-GPG-KEY-CentOS-7
enabled=1

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-7.9.2009 - Plus
baseurl=http://mirrors.aliyun.com/centos-altarch/7.9.2009/centosplus/$(uname -m)/
gpgcheck=0
enabled=0
gpgkey=http://mirrors.aliyun.com/centos-altarch/7/os/$(uname -m)/RPM-GPG-KEY-CentOS-7
EOF
    fi
    if [ $? == 0 ]; then
        info Yum源添加成功...
    else
        error Yum源添加失败...
    fi
}

# 添加apt源
add_apt_repo() {
    cpu_type
    mkdir -p /tmp/apt
    if [ "$CPU_TYPE" = "x86_64" ]; then
        tee /tmp/apt/sources.list >/dev/null <<EOF
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu focal stable
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
    else
        tee /tmp/apt/sources.list >/dev/null <<EOF
deb http://mirrors.aliyun.com/ubuntu-ports/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports/ focal-backports main restricted universe multiverse
deb [arch=arm64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu focal stable
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
    fi
    if [ $? == 0 ]; then
        info Apt源添加成功...
    else
        error Apt源添加失败...
    fi
}

# 启动centos容器
run_centos_container() {
    cpu_type
    if docker ps -a --format '{{.Names}}' | grep -q "^centos7.9$"; then
        docker rm -f centos7.9
        info 删除centos7.9容器...
    else
        info 容器centos7.9不存在，将启动新容器...
    fi
    info 启动centos7.9容器...
    docker run --name centos7.9 -d -it \
        -v /tmp/yum.repos.d/:/etc/yum.repos.d/ \
        -v /$LOCAL_PATH/:/mnt/ \
        --platform $CPU_TYPE \
        centos:7.9.2009 bash
}

#  启动ubuntu容器
run_ubuntu_container() {
    cpu_type
    if docker ps -a --format '{{.Names}}' | grep -q "^ubuntu20.04$"; then
        docker rm -f ubuntu20.04
        info 删除ubuntu20.04容器...
    else
        info 容器ubuntu20.04不存在，将启动新容器...
    fi
    info 启动ubuntu20.04容器...
    docker run --name ubuntu20.04 -d -it \
        -v /tmp/apt/sources.list:/etc/apt/sources.list \
        -v /$LOCAL_PATH/:/mnt/ \
        --platform $CPU_TYPE \
        ubuntu:20.04 bash
}

# 下载ansible及其依赖包
download_ansible_rpm() {
    tee /tmp/download.sh >/dev/null <<'EOF'
#!/bin/bash
mkdir -p /mnt/ansible_rpm 
cd /mnt/ansible_rpm && rm -rf *
yum makecache 
yum install --downloadonly --downloaddir=./ ansible python3
EOF
    chmod +x /tmp/download.sh &&
        docker cp /tmp/download.sh centos7.9:/tmp/download.sh &&
        docker exec -i centos7.9 /bin/bash -c "/tmp/download.sh"
}

download_ansible_deb() {
    tee /tmp/download.sh >/dev/null <<'EOF'
#!/bin/bash
mkdir -p /mnt/ansible_deb
cd /mnt/ansible_deb && rm -rf *
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 871920D1991BC93C
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8 # docker-ce
apt-get update
apt-get download $(apt-cache depends ansible | egrep 'Depends|Recommends|Suggests' | awk '{print $2}' | tr -d '<>')
EOF

    chmod +x /tmp/download.sh &&
        docker cp /tmp/download.sh ubuntu20.04:/tmp/download.sh &&
        docker exec -i ubuntu20.04 /bin/bash -c "/tmp/download.sh"

}

save_ansible() {
    cpu_type
    rm -rf /$LOCAL_PATH/ansible-$CPU_TYPE.tar.gz && cd /$LOCAL_PATH/
    tar -zcPf ansible-$CPU_TYPE.tar.gz ansible_rpm/ ansible_deb/
    rsync -avzP /$LOCAL_PATH/ansible-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/ansible/
    if [ $? == 0 ]; then
        info Ansible成功打包上传到:http://$DL_SERVER
    else
        error Ansible打包上传失败...
    fi
}

save_k3s() {
    cpu_type
    mkdir -p /$LOCAL_PATH
    curl https://get.k3s.io -o /$LOCAL_PATH/k3s-install.sh
    if [ $CPU_TYPE == "x86_64" ]; then
        wget $K3S_GITHUB/k3s -c -O /$LOCAL_PATH/k3s
        wget $K3S_GITHUB/k3s-airgap-images-amd64.tar -c -P /$LOCAL_PATH/
        cd /$LOCAL_PATH/ && tar -zcf k3s-$K3S_VERSION-$CPU_TYPE.tar.gz k3s-install.sh k3s k3s-airgap-images-amd64.tar
        rm -rf k3s*
        rsync -avzP k3s-$K3S_VERSION-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/k3s/
    elif [ $CPU_TYPE == "arm64" ]; then
        wget $K3S_GITHUB/k3s-arm64 -c -O /$LOCAL_PATH/k3s
        wget $K3S_GITHUB/k3s-airgap-images-arm64.tar -c -P /$LOCAL_PATH/
        cd /$LOCAL_PATH/ && tar -zcf k3s-$K3S_VERSION-$CPU_TYPE.tar.gz k3s-install.sh k3s k3s-airgap-images-arm64.tar
        rm -rf k3s*
        rsync -avzP k3s-$K3S_VERSION-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/k3s/
    else
        error 不支持该系统架构...
    fi
    if [ $? == 0 ]; then
        info k3s成功打包上传到:http://$DL_SERVER
    else
        error k3s打包上传失败...
    fi
}

main() {
    create_local_path
    update_hosts
    add_yum_repo
    add_apt_repo
    run_centos_container
    run_ubuntu_container
    download_ansible_rpm
    download_ansible_deb
    save_ansible
    save_k3s
}

main

# 下载docker-ce及其依赖包
DOCKER_VERSION=20.10.17
mkdir /mnt/docker-ce
yum install --downloadonly --downloaddir=/mnt/docker-ce docker-ce-$DOCKER_VERSION

# 下载kubernetes及其依赖包
K8S_VERSION=1.26.3
mkdir /mnt/k8s
yum install --downloadonly --downloaddir=/mnt/k8s kubeadm-$K8S_VERSION kubeactl-$K8S_VERSION kubelet-$K8S_VERSION

# 下载docker二进制包
DOCKER_VERSION=20.10.17
wget https://download.docker.com/linux/static/stable/x86_64/docker-$DOCKER_VERSION.tgz -c -P /mnt/
wget https://download.docker.com/linux/static/stable/aarch64/docker-$DOCKER_VERSION.tgz -c -P /mnt/

# 下载docker-compose二进制包
DOCKER_COMPOSE_VERSIN=v2.20.3
wget https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSIN/docker-compose-linux-x86_64 -c -P /mnt/
wget https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSIN/docker-compose-linux-aarch64 -c -P /mnt/

# 下载k9s二进制包
K9S_VERSION=v0.31.7
wget https://github.com/derailed/k9s/releases/download/$K9S_VERSION/k9s_Linux_amd64.tar.gz -c -P /mnt/
wget https://github.com/derailed/k9s/releases/download/$K9S_VERSION/k9s_Linux_arm64.tar.gz -c -P /mnt/

# 下载helm二进制包
HELM_VERSION=v3.12.3
wget https://get.helm.sh/helm-$HELM_VERSION-linux-amd64.tar.gz -c -P /mnt/
wget https://get.helm.sh/helm-$HELM_VERSION-linux-arm64.tar.gz -c -P /mnt/
