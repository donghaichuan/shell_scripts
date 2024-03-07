#!/bin/bash
set -x
# set -e
# 脚本功能：简化安装的命令操作

# 指定传参变量名
action=$1
components_name=$2

# 将命令重复部分作为变量
exec_ansible='sudo docker exec -i ansible /bin/bash -c'
playbook_install='ansible-playbook deploy.yml -e "@vars.yml"'
playbook_uninstall='ansible-playbook uninstall.yml -e "@vars.yml"'

# 准备ansible.log文件
sudo rm -rf ansible.log && touch ansible.log

# 脚本的帮助手册
function usage(){
cat <<EOF
Usage:
  -h or --help  帮助手册
  install       安装服务
  uninstall     卸载服务
EOF
}

# 输出脚本支持的服务有哪些
function components_list(){
cat <<EOF
Usage:
  monitor       monitor服务
EOF
}

# 检查系统ansible
function check_ansible_system(){
  stat /usr/bin/ansible > /dev/null 2>&1
  if [ $? = 0 ];then
    export ansible_type=system
  else
    export ansible_type=container
  fi
}

# 启动ansible容器
function run_ansible_container(){
  sudo docker images |grep ansible_ubuntu
  if [ $? != 0 ];then
    echo -e "\033[1;32m--------ansible镜像不存在,导入ansible镜像--------\033[0m\n"
    tar zxf ../deploy-ansible-container.tar.gz && bash deploy-ansible-container.sh $PWD
  fi
  echo -e "\033[1;32m--------ansible镜像已存在,启动ansible容器--------\033[0m\n"
  sudo docker rm -f ansible > /dev/null 2>&1
  sudo docker run --name ansible -d -v $PWD:/data -v $HOME/.ssh:/root/.ssh ansible_ubuntu:v2.9.6
  sleep 5
}

# 安装服务(容器)
function container_components_install(){
  run_ansible_container
  case $components_name in
    monitor)
      $exec_ansible "$playbook_install"
      ;;
    *)
      echo "Invalid components_name: $components_name"
      exit 1
      ;;
  esac
}

# 安装服务（本地）
function components_install(){
  case $components_name in
    monitor)
      eval $playbook_install
      ;;
    *)
      echo "Invalid components_name: $components_name"
      exit 1
      ;;
  esac
}

# 卸载服务（容器）
function container_components_uninstall(){
  run_ansible_container
  case $components_name in
    monitor)
      $exec_ansible "$playbook_uninstall"
      ;;
    *)
      echo "Invalid components_name: $components_name"
      exit 1
      ;;
  esac
}

# 卸载服务（本地）
function components_uninstall(){
  case $components_name in
    monitor)
      eval $playbook_uninstall
      ;;
    *)
      echo "Invalid components_name: $components_name"
      exit 1
      ;;
  esac
}

# 主函数
function main(){
  case "$#" in
    0)
      usage
      exit 1
      ;;
    1)
      if [ "$action" = "--help" ] || [ "$action" = "-h" ]; then
        usage
        exit 1
      elif [ "$action" != "install" ] && [ "$action" != "uninstall" ]; then
        echo "Invalid action: $action"
        exit 1
      else
        components_list
        exit 1
      fi
      ;;
    2)
      if [ "$action" == "install" ]; then
        check_ansible_system
        if [ "$ansible_type" == "system" ]; then
          components_install
        else
          container_components_install
        fi
      elif [ "$action" == "uninstall" ]; then
        check_ansible_system
        if [ "$ansible_type" == "system" ]; then
          components_uninstall
        else
          container_components_uninstall
        fi
      else
        echo "Invalid action: $action"
        exit 1
      fi
      ;;
    *)
      echo "Invalid number of arguments"
      exit 1
      ;;
  esac
}

# 启动脚本
main "$@"