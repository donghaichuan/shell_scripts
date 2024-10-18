#! /bin/bash

# 准备ansible，nfs，docker，docker-compose，k8s，k3s，k9s，helm。。。离线包
# set -e
set -x
set -o noglob

# 定义变量
LOCAL_PATH=/offline_pkgs_path
DL_SERVER=dl.tsingj.local/offline_install
RSYNC_SERVER=rsync.tsingj.local::offline_install
DOCKER_VERSION=20.10.21
DOCKER_URL=https://download.docker.com/linux/static/stable
K9S_VERSION=v0.31.7
K9S_URL=https://github.com/derailed/k9s/releases/download
HELM_VERSION=v3.12.3
HELM_URL=https://get.helm.sh
DOCKER_COMPOSE_VERSIN=v2.20.3
DOCKER_COMPOSE_URL=https://github.com/docker/compose/releases/download
K3S_VERSION=v1.27.5
K3S_GITHUB=https://github.com/k3s-io/k3s/releases/download/$K3S_VERSION%2Bk3s1


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
EOF
    else
        tee /tmp/apt/sources.list >/dev/null <<EOF
deb http://mirrors.aliyun.com/ubuntu-ports/ focal main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports/ focal-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports/ focal-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports/ focal-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports/ focal-backports main restricted universe multiverse
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
        -v $LOCAL_PATH/:/mnt/ \
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
        -v $LOCAL_PATH/:/mnt/ \
        --platform $CPU_TYPE \
        ubuntu:20.04 bash
        # -v /tmp/apt/sources.list:/etc/apt/sources.list \
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
apt-get update
apt-get download $(apt-cache depends ansible | grep -E 'Depends|Recommends' | awk '{print $2}' | tr -d '<>';echo ansible)
EOF

    chmod +x /tmp/download.sh &&
        docker cp /tmp/download.sh ubuntu20.04:/tmp/download.sh &&
        docker exec -i ubuntu20.04 /bin/bash -c "/tmp/download.sh"

}

save_ansible() {
    cpu_type
    rm -rf $LOCAL_PATH/ansible-$CPU_TYPE.tar.gz && cd $LOCAL_PATH/
    tee install_ansible.sh >/dev/null <<'EOF'
#!/bin/bash
source /etc/os-release

# rpm包安装ansible
install_ansible_rpm(){
    sudo rpm -ivh ansible_rpm/*.rpm  --nodeps --force
}

# deb包安装ansible
install_ansible_deb(){
    sudo dpkg -i --force-depends ansible_deb/*.deb
}

# 默认执行的入口脚本
main(){
    case $ID in
        centos|CentOS)
        install_ansible_rpm
        ;;
        ubuntu|Ubuntu)
        install_ansible_deb
        ;;
        sles|SLES)
        install_ansible_rpm
        ;;
        neokylin)
        install_ansible_rpm
        ;;
        kylin)
        python3_version=$(python3 -V | awk '{print $2}' | awk -F'.' '{print $1"."$2}')
        install_ansible_rpm
        rm -rf /usr/bin/python3 && ln -s /usr/bin/python$python3_version /usr/bin/python3
        ;;
        *)
	echo "Invalid system..."
        exit 1
        ;;
    esac
}

# 启动脚本
main
EOF
    chmod +x install_ansible.sh
    tar -zcPf ansible-$CPU_TYPE.tar.gz ansible_rpm/ ansible_deb/ install_ansible.sh
    rsync -avzP $LOCAL_PATH/ansible-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/ansible/
    if [ $? == 0 ]; then
        info Ansible成功打包上传到:http://$DL_SERVER
    else
        error Ansible打包上传失败...
    fi
}

# 下载nfs和常用包及其依赖包
download_nfs_rpm() {
    tee /tmp/download_nfs.sh >/dev/null <<'EOF'
#!/bin/bash
mkdir -p /mnt/nfs-utils 
cd /mnt/nfs-utils && rm -rf *
yum makecache 
yum install --downloadonly --downloaddir=./ nfs-utils ipvsadm ipset iproute tmux telnet net-tools 
EOF
    chmod +x /tmp/download_nfs.sh &&
        docker cp /tmp/download_nfs.sh centos7.9:/tmp/download_nfs.sh &&
        docker exec -i centos7.9 /bin/bash -c "/tmp/download_nfs.sh"
}

download_nfs_deb() {
    tee /tmp/download_nfs.sh >/dev/null <<'EOF'
#!/bin/bash
mkdir -p /mnt/nfs-kernel-server
cd /mnt/nfs-kernel-server && rm -rf *
apt-get update
pkg_names=(
nfs-kernel-server 
rpcbind
ipvsadm 
ipset 
tmux 
telnet 
net-tools
)
for pkg_name in ${pkg_names[@]};do
    apt-get download $(apt-cache depends $pkg_name | grep -E 'Depends|Recommends' | awk '{print $2}' | tr -d '<>';echo $pkg_name)
done
EOF

    chmod +x /tmp/download_nfs.sh &&
        docker cp /tmp/download_nfs.sh ubuntu20.04:/tmp/download_nfs.sh &&
        docker exec -i ubuntu20.04 /bin/bash -c "/tmp/download_nfs.sh"

}

save_nfs() {
    cpu_type
    rm -rf $LOCAL_PATH/nfs_packages-$CPU_TYPE.tar.gz && cd $LOCAL_PATH/
    tar -zcPf nfs_packages-$CPU_TYPE.tar.gz nfs-utils/ nfs-kernel-server/
    rsync -avzP $LOCAL_PATH/nfs_packages-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/nfs_packages/
    if [ $? == 0 ]; then
        info NFS成功打包上传到:http://$DL_SERVER
    else
        error NFS打包上传失败...
    fi
}

# 下载k8s及其依赖包
download_k8s_rpm() {
    cpu_type
    if [ $CPU_TYPE == "x86_64" ]; then
    cat <<EOF > /tmp/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
    elif [ $CPU_TYPE == "arm64" ]; then
cat <<EOF > /tmp/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-aarch64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
    else
        error 不支持该系统架构...
    fi
    tee /tmp/download_k8s.sh >/dev/null <<'EOF'
#!/bin/bash
K8S_VERSION=1.26.3
mkdir -p /mnt/k8s_rpm 
cd /mnt/k8s_rpm && rm -rf *
yum clean all && yum makecache && 
yum install --nogpgcheck --downloadonly --downloaddir=./ kubeadm-$K8S_VERSION kubeactl-$K8S_VERSION kubelet-$K8S_VERSION
EOF
    chmod +x /tmp/download_k8s.sh &&
        docker cp /tmp/download_k8s.sh centos7.9:/tmp/download_k8s.sh &&
        docker exec -i centos7.9 /bin/bash -c "/tmp/download_k8s.sh"
}

download_k8s_deb() {
    tee /tmp/download_k8s.sh >/dev/null <<'EOF'
#!/bin/bash
apt update && apt install -y apt-transport-https gnupg2 curl ca-certificates
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
echo "deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" >> /etc/apt/sources.list.d/k8s.list

K8S_VERSION=1.26.3
mkdir -p /mnt/k8s_deb
cd /mnt/k8s_deb && rm -rf *
apt-get update
pkg_names=(
kubeadm=$K8S_VERSION-00
kubectl=$K8S_VERSION-00
kubelet=$K8S_VERSION-00
)
for pkg_name in ${pkg_names[@]};do
    apt-get download $(apt-cache depends $pkg_name | grep -E 'Depends|Recommends' | awk '{print $2}' | tr -d '<>';echo $pkg_name)
done
rm -rf /etc/apt/sources.list.d/k8s.list
EOF

    chmod +x /tmp/download_k8s.sh &&
        docker rm -f ubuntu20.04 &&
        docker run --name ubuntu20.04 -it -d -v $LOCAL_PATH/:/mnt/ ubuntu:20.04 bash &&
        docker cp /tmp/download_k8s.sh ubuntu20.04:/tmp/download_k8s.sh &&
        docker exec -i ubuntu20.04 /bin/bash -c "/tmp/download_k8s.sh"

}

save_k8s() {
    cpu_type
    K8S_VERSION=1.26.3
    rm -rf $LOCAL_PATH/k8s_packages-$K8S_VERSION-$CPU_TYPE.tar.gz && cd $LOCAL_PATH/
    tar -zcPf k8s_packages-$K8S_VERSION-$CPU_TYPE.tar.gz k8s_rpm/ k8s_deb/
    rsync -avzP $LOCAL_PATH/k8s_packages-$K8S_VERSION-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/k8s/
    if [ $? == 0 ]; then
        info Kubernetes成功打包上传到:http://$DL_SERVER
    else
        error Kubernetes打包上传失败...
    fi
}

# 下载docker-ce及其依赖包
download_dockerce_rpm() {
    tee /tmp/download_dockerce.sh >/dev/null <<'EOF'
#!/bin/bash
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
DOCKERCE_VERSION=20.10.21
mkdir -p /mnt/dockerce_rpm 
cd /mnt/dockerce_rpm && rm -rf *
yum clean all && yum makecache && 
yum install --nogpgcheck --downloadonly --downloaddir=./ docker-ce-$DOCKERCE_VERSION docker-ce-cli-$DOCKERCE_VERSION
EOF
    chmod +x /tmp/download_dockerce.sh &&
        docker cp /tmp/download_dockerce.sh centos7.9:/tmp/download_dockerce.sh &&
        docker exec -i centos7.9 /bin/bash -c "/tmp/download_dockerce.sh"
}

download_dockerce_deb() {
    cpu_type
    tee /tmp/download_dockerce.sh >/dev/null <<'EOF'
#!/bin/bash
apt update && apt install -y apt-transport-https gnupg2 curl ca-certificates
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | apt-key add -
if [ $(uname -m) = "x86_64" ]; then
    echo "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu focal stable" >> /etc/apt/sources.list.d/dockerce.list
elif [ $(uname -m) = "aarch64" ]; then
    echo "deb [arch=arm64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu focal stable" >> /etc/apt/sources.list.d/dockerce.list
fi
DOCKERCE_VERSION=20.10.21
mkdir -p /mnt/dockerce_deb
cd /mnt/dockerce_deb && rm -rf *
apt-get update
pkg_names=(
docker-ce=5:$DOCKERCE_VERSION~3-0~ubuntu-focal
docker-ce-cli=5:$DOCKERCE_VERSION~3-0~ubuntu-focal
)
for pkg_name in ${pkg_names[@]};do
    apt-get download $(apt-cache depends $pkg_name | grep -E 'Depends|Recommends' | \
    awk '{print $2}' | tr -d '<>';echo $pkg_name)
done
rm -rf /etc/apt/sources.list.d/dockerce.list
EOF

    chmod +x /tmp/download_dockerce.sh &&
        docker rm -f ubuntu20.04 &&
        docker run --name ubuntu20.04 -it -d -v $LOCAL_PATH/:/mnt/ ubuntu:20.04 bash &&
        docker cp /tmp/download_dockerce.sh ubuntu20.04:/tmp/download_dockerce.sh &&
        docker exec -i ubuntu20.04 /bin/bash -c "/tmp/download_dockerce.sh"

}

save_dockerce() {
    cpu_type
    DOCKERCE_VERSION=20.10.21
    rm -rf $LOCAL_PATH/dockerce_packages-$DOCKERCE_VERSION-$CPU_TYPE.tar.gz && cd $LOCAL_PATH/
    tar -zcPf dockerce_packages-$DOCKERCE_VERSION-$CPU_TYPE.tar.gz dockerce_rpm/ dockerce_deb/
    rsync -avzP $LOCAL_PATH/dockerce_packages-$DOCKERCE_VERSION-$CPU_TYPE.tar.gz \
    $RSYNC_SERVER/$CPU_TYPE/dockerce/
    if [ $? == 0 ]; then
        info Kubernetes成功打包上传到:http://$DL_SERVER
    else
        error Kubernetes打包上传失败...
    fi
}

save_docker(){
    cpu_type
    mkdir -p $LOCAL_PATH && cd $LOCAL_PATH 
    if [ $CPU_TYPE == "x86_64" ]; then
        wget $DOCKER_URL/x86_64/docker-$DOCKER_VERSION.tgz -c -O $LOCAL_PATH/docker-$DOCKER_VERSION-$CPU_TYPE.tgz
    elif [ $CPU_TYPE == "arm64" ]; then
        wget $DOCKER_URL/aarch64/docker-$DOCKER_VERSION.tgz -c -O $LOCAL_PATH/docker-$DOCKER_VERSION-$CPU_TYPE.tgz
    else
        error 不支持该系统架构...
    fi
    rsync -avzP docker-$DOCKER_VERSION-$CPU_TYPE.tgz $RSYNC_SERVER/$CPU_TYPE/docker/
    if [ $? == 0 ]; then
        info Docker成功打包上传到:http://$DL_SERVER
    else
        error Docker打包上传失败...
    fi
}

save_k3s() {
    cpu_type
    mkdir -p $LOCAL_PATH && cd $LOCAL_PATH
    curl https://get.k3s.io -o $LOCAL_PATH/k3s-install.sh
    if [ $CPU_TYPE == "x86_64" ]; then
        wget $K3S_GITHUB/k3s -c -O $LOCAL_PATH/k3s
        wget $K3S_GITHUB/k3s-airgap-images-amd64.tar -c -P $LOCAL_PATH/
        tar -zcf k3s-$K3S_VERSION-$CPU_TYPE.tar.gz k3s-install.sh k3s k3s-airgap-images-amd64.tar
        rm -rf k3s*
        rsync -avzP k3s-$K3S_VERSION-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/k3s/
    elif [ $CPU_TYPE == "arm64" ]; then
        wget $K3S_GITHUB/k3s-arm64 -c -O $LOCAL_PATH/k3s
        wget $K3S_GITHUB/k3s-airgap-images-arm64.tar -c -P $LOCAL_PATH/
        tar -zcf k3s-$K3S_VERSION-$CPU_TYPE.tar.gz k3s-install.sh k3s k3s-airgap-images-arm64.tar
        rm -rf k3s*
        rsync -avzP k3s-$K3S_VERSION-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/k3s/
    else
        error 不支持该系统架构...
    fi
    if [ $? == 0 ]; then
        info K3S成功打包上传到:http://$DL_SERVER
    else
        error K3S打包上传失败...
    fi
}

save_k9s() {
    cpu_type
    mkdir -p $LOCAL_PATH && cd $LOCAL_PATH
    if [ $CPU_TYPE == "x86_64" ]; then
        wget $K9S_URL/$K9S_VERSION/k9s_Linux_amd64.tar.gz \
        -c -O $LOCAL_PATH/k9s_Linux-$K9S_VERSION-$CPU_TYPE.tar.gz 
    elif [ $CPU_TYPE == "arm64" ]; then
        wget $K9S_URL/$K9S_VERSION/k9s_Linux_arm64.tar.gz \
        -c -O $LOCAL_PATH/k9s_Linux-$K9S_VERSION-$CPU_TYPE.tar.gz
    else
        error 不支持该系统架构...
    fi
    rsync -avzP k9s_Linux-$K9S_VERSION-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/k9s/
    if [ $? == 0 ]; then
        info K9S成功打包上传到:http://$DL_SERVER
    else
        error K9S打包上传失败...
    fi
}

save_helm(){
    cpu_type
    mkdir -p $LOCAL_PATH && cd $LOCAL_PATH
    if [ $CPU_TYPE == "x86_64" ]; then
        wget $HELM_URL/helm-$HELM_VERSION-linux-amd64.tar.gz \
        -c -O $LOCAL_PATH/helm-$HELM_VERSION-linux-$CPU_TYPE.tar.gz
    elif [ $CPU_TYPE == "arm64" ]; then
        wget $HELM_URL/helm-$HELM_VERSION-linux-arm64.tar.gz \
        -c -O $LOCAL_PATH/helm-$HELM_VERSION-linux-$CPU_TYPE.tar.gz
    else
        error 不支持该系统架构...
    fi
    rsync -avzP helm-$HELM_VERSION-linux-$CPU_TYPE.tar.gz $RSYNC_SERVER/$CPU_TYPE/helm/
    if [ $? == 0 ]; then
        info HELM成功打包上传到:http://$DL_SERVER
    else
        error HELM打包上传失败...
    fi
}

save_docker_compose(){
    cpu_type
    mkdir -p $LOCAL_PATH && cd $LOCAL_PATH
    if [ $CPU_TYPE == "x86_64" ]; then
        wget $DOCKER_COMPOSE_URL/$DOCKER_COMPOSE_VERSIN/docker-compose-linux-x86_64 \
        -c -O $LOCAL_PATH/docker-compose-linux-$DOCKER_COMPOSE_VERSIN-$CPU_TYPE
    elif [ $CPU_TYPE == "arm64" ]; then
        wget $DOCKER_COMPOSE_URL/$DOCKER_COMPOSE_VERSIN/docker-compose-linux-aarch64 \
        -c -O $LOCAL_PATH/docker-compose-linux-$DOCKER_COMPOSE_VERSIN-$CPU_TYPE
    else
        error 不支持该系统架构...
    fi
    rsync -avzP docker-compose-linux-$DOCKER_COMPOSE_VERSIN-$CPU_TYPE \
    $RSYNC_SERVER/$CPU_TYPE/docker-compose/
    if [ $? == 0 ]; then
        info Docker-compose成功打包上传到:http://$DL_SERVER
    else
        error Docker-compose打包上传失败...
    fi
}

delete_local_path(){
    # rm -rf $LOCAL_PATH
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
    download_nfs_rpm
    download_nfs_deb
    save_nfs
    download_k8s_rpm
    download_k8s_deb
    save_k8s
    download_dockerce_rpm
    download_dockerce_deb
    save_dockerce
    save_docker
    save_k3s
    save_k9s
    save_helm
    save_docker_compose
    delete_local_path
}

main
