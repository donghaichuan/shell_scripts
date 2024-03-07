#! /bin/bash

# 拉取calico镜像
harbor_project=harbor.tsingj.local/k8s
image_tag=1.26.3
image_name=(
    # k8s镜像列表
    kube-apiserver:v$image_tag
    kube-controller-manager:v$image_tag
    kube-scheduler:v$image_tag
    kube-proxy:v$image_tag
    coredns:v1.9.3
    pause:3.9
    etcd:3.5.6-0

    # calico镜像列表
    calico/cni:v3.26.0
    calico/node:v3.26.0
    calico/kube-controllers:v3.26.0

    # nfs-client-provisioner镜像列表
    nfs-subdir-external-provisioner:v4.0.1

    # metrics-server镜像列表
    metrics-server:v0.6.2

    # kube-vip镜像列表
    kube-vip:v0.5.9

)

save_amd64_image(){
    export CPU_TYPE=x86_64
    for i in ${image_name[@]};do
        docker pull $harbor_project/$i --platform=amd64
        image_paths+=($(docker inspect --format='{{.RepoTags}}' $harbor_project/$i | cut -d '[' -f 2 | cut -d ']' -f 1)) 
    done
    docker save "${image_paths[@]}" | gzip > k8s_images-$image_tag-$CPU_TYPE.tar.gz
    docker rmi "${image_paths[@]}"
    rsync -avzP k8s_images-$image_tag-$CPU_TYPE.tar.gz rsync.tsingj.local::offline_install/$CPU_TYPE/k8s/
}

save_arm64_image(){
    export CPU_TYPE=arm64
    for i in ${image_name[@]};do
        docker pull $harbor_project/$i --platform=arm64
        image_paths+=($(docker inspect --format='{{.RepoTags}}' $harbor_project/$i | cut -d '[' -f 2 | cut -d ']' -f 1)) 
    done
    docker save "${image_paths[@]}" | gzip > k8s_images-$image_tag-$CPU_TYPE.tar.gz
    docker rmi "${image_paths[@]}"
    rsync -avzP k8s_images-$image_tag-$CPU_TYPE.tar.gz rsync.tsingj.local::offline_install/$CPU_TYPE/k8s/
}

main(){
    save_amd64_image
    save_arm64_image
}

main