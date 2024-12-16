#!/bin/bash

docker run -d \
      --restart=always \
      --privileged \
      --name=bind9 \
      -p 53:53/tcp \
      -p 53:53/udp \
      -v $PWD/conf:/etc/bind \
      -e TZ=CST \
      harbor.tsingj.local/k8s/bind9:9.16-20.04_edge