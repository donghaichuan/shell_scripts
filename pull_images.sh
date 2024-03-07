#! /bin/bash

# 拉取calico镜像
# remote_registry=gcr.io/k8s-staging-sig-storage
# remote_registry=docker.io
# local_registry=harbor.tsingj.local/k8s
# image_tag=v3.8.5
# image_name=(
# # mysql:$image_tag
# calico/node:$image_tag
# calico/pod2daemon-flexvol:$image_tag
# calico/kube-controllers:$image_tag
# calico/cni:$image_tag
# )

remote_registry=docker.io
local_registry=harbor.tsingj.local/devops
image_tag=3.9.10
image_name=(
    python:$image_tag
)

remote_registry=registry.k8s.io
local_registry=harbor.tsingj.local/k8s
image_tag=v1.26.3
image_name=(
    kube-apiserver:$image_tag
    kube-controller-manager:$image_tag
    kube-scheduler:$image_tag
    kube-proxy:$image_tag
    pause:3.9
    etcd:3.5.6-0
    coredns/coredns:v1.9.3
)

pull_amd64_image() {
    for i in ${image_name[@]}; do
        docker pull $remote_registry/$i --platform=amd64
        docker tag $remote_registry/$i $local_registry/amd64/$i
        docker push $local_registry/amd64/$i
        docker rmi $remote_registry/$i
    done
}

pull_arm64_image() {
    for i in ${image_name[@]}; do
        docker pull $remote_registry/$i --platform=arm64
        docker tag $remote_registry/$i $local_registry/arm64/$i
        docker push $local_registry/arm64/$i
        docker rmi $remote_registry/$i
    done
}

create_manifest() {
    for i in ${image_name[*]}; do
        docker manifest create --insecure $local_registry/$i $local_registry/amd64/$i $local_registry/arm64/$i
        docker manifest push --insecure $local_registry/$i
    done
}

main() {
    pull_amd64_image
    pull_arm64_image
    create_manifest
}

main $@
