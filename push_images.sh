#!/bin/bash

# 获取本地所有镜像列表
images=$(docker images --format "{{.Repository}}:{{.Tag}}")

# 新私有仓库地址
new_private_registry="harbor.test.local/dhc"

# 遍历每个镜像并重新标记并上传到新私有仓库
for image in $images; do
    old_image=$image
    # 获取镜像最后一个斜杠后边的部分
    image_suffix=$(echo $image | awk -F '/' '{print $NF}')
    new_image=$new_private_registry/$image_suffix
    docker tag $old_image $new_image
    docker push $new_image
done
