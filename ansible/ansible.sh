#!/bin/bash
docker run --name ansible -d \
  --privileged \
  --env-file ansible.env \
  -v $PWD:$PWD \
  -v $HOME/.ssh:/root/.ssh \
  -v $HOME/.kube:/root/.kube \
  harbor.tsingj.local/k8s/ansible:v2.9.6-dev1 >/dev/null 2>&1
