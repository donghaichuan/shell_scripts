#! /bin/bash

# 拉取calico镜像
harbor_project=harbor.tsingj.local/k8s
image_tag=v1.26.3
image_name=(
# kube-apiserver:$image_tag
# kube-controller-manager:$image_tag
# kube-scheduler:$image_tag
# kube-proxy:$image_tag
# coredns:v1.9.3
# pause:3.9
# etcd:3.5.6-0
calico/cni:v3.26.0
calico/node:v3.26.0
calico/kube-controllers:v3.26.0
)

save_amd64_image(){
    for i in ${image_name[@]};
    do
        docker pull $harbor_project/$i --platform=amd64
        # docker save -o calico.tar $harbor_project/$i 
        # docker rmi $i
    done
    # docker save -o k8simage-harbor.tar \
    # $harbor_project/kube-apiserver:$image_tag  \
    # $harbor_project/kube-controller-manager:$image_tag \
    # $harbor_project/kube-scheduler:$image_tag \
    # $harbor_project/kube-proxy:$image_tag \
    # $harbor_project/etcd:3.5.6-0 \
    # $harbor_project/coredns:v1.9.3 \
    # $harbor_project/pause:3.9
    docker save -o calico-3.26.0.tar \
    $harbor_project/calico/cni:v3.26.0 \
    $harbor_project/calico/node:v3.26.0 \
    $harbor_project/calico/kube-controllers:v3.26.0

    rsync -avzP calico-3.26.0.tar rsync.tsingj.local::offline_install/kubernetes-1.26.3/
}

# pull_arm64_image(){
#     for i in ${image_name[*]};
#     do
#         docker pull $i --platform=arm64
#         docker tag $i $harbor_project/arm64/$i
#         docker push $harbor_project/arm64/$i
#         docker rmi $i
#     done
# }

main(){
    save_amd64_image
}

main $@