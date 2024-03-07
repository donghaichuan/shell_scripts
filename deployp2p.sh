#!/bin/bash
set -x
# set -e
# 脚本功能：简化安装的命令操作

# 指定传参变量名
action=$1
components_name=$2

# 将命令重复部分作为变量
exec_ansible='docker exec -i ansible /bin/bash -c'
playbook_install='ansible-playbook install.yaml -e "@all_vars.yaml"'
playboook_uninstall='ansible-playbook uninstall_application_service.yaml -e "@all_vars.yaml"'

# 脚本的帮助手册
function usage() {
  cat <<EOF
Usage:
  -h or --help  帮助手册
  install       安装服务
  uninstall     卸载服务
EOF
}

# 输出脚本支持的服务有哪些
function components_list() {
  cat <<EOF
Usage:
  all           所有服务
  redis         redis服务
  mysql         mysql服务
  tm            tm服务
  ds            ds服务
  dmz           dmz服务
  data          redis和mysql服务
  app           tm,ds,dmz服务
EOF
}

# 检查系统ansible
function check_ansible_system() {
  stat /usr/bin/ansible >/dev/null 2>&1
  if [ $? = 0 ]; then
    export ansible_type=system
  else
    export ansible_type=container
  fi
}

# 启动ansible容器
function run_ansible_container() {
  docker images | grep ansible_ubuntu
  if [ $? != 0 ]; then
    echo -e "\033[1;32m--------ansible镜像不存在,导入ansible镜像--------\033[0m\n"
    tar zxf ../deploy-ansible-container.tar.gz && bash deploy-ansible-container.sh $PWD
  fi
  echo -e "\033[1;32m--------ansible镜像已存在,启动ansible容器--------\033[0m\n"
  docker rm -f ansible >/dev/null 2>&1
  docker run --name ansible -d -v $PWD:/data ansible_ubuntu:v2.9.6
  sleep 5
}

# 安装服务(容器)
function conatainer_components_install() {
  run_ansible_container
  case $components_name in
  all)
    $exec_ansible "$playbook_install"
    ;;
  redis)
    $exec_ansible "$playbook_install -t install_redis"
    ;;
  mysql)
    $exec_ansible "$playbook_install -t install_mysql"
    ;;
  tm)
    $exec_ansible "$playbook_install -t install_tm"
    ;;
  ds)
    $exec_ansible "$playbook_install -t install_ds"
    ;;
  dmz)
    $exec_ansible "$playbook_install -t install_dmz"
    ;;
  data)
    $exec_ansible "$playbook_install -t install_data"
    ;;
  app)
    $exec_ansible "$playbook_install -t install_app"
    ;;
  *)
    echo "Invalid components_name: $components_name"
    exit 1
    ;;
  esac
}

# 安装服务（本地）
function components_install() {
  case $components_name in
  all)
    eval $playbook_install
    ;;
  redis)
    eval $playbook_install -t install_redis
    ;;
  mysql)
    eval $playbook_install -t install_mysql
    ;;
  tm)
    eval $playbook_install -t install_tm
    ;;
  ds)
    eval $playbook_install -t install_ds
    ;;
  dmz)
    eval $playbook_install -t install_dmz
    ;;
  data)
    eval $playbook_install -t install_data
    ;;
  app)
    eval $playbook_install -t install_app
    ;;
  *)
    echo "Invalid components_name: $components_name"
    exit 1
    ;;
  esac
}

# 卸载服务（容器）
function conatainer_components_uninstall() {
  run_ansible_container
  case $components_name in
  all)
    $exec_ansible "$playboook_uninstall"
    ;;
  redis)
    $exec_ansible "$playboook_uninstall -t uninstall_redis"
    ;;
  mysql)
    $exec_ansible "$playboook_uninstall -t uninstall_mysql"
    ;;
  tm)
    $exec_ansible "$playboook_uninstall -t uninstall_tm"
    ;;
  ds)
    $exec_ansible "$playboook_uninstall -t uninstall_ds"
    ;;
  dmz)
    $exec_ansible "$playboook_uninstall -t uninstall_dmz"
    ;;
  data)
    $exec_ansible "$playboook_uninstall -t uninstall_data"
    ;;
  app)
    $exec_ansible "$playboook_uninstall -t uninstall_app"
    ;;
  *)
    echo "Invalid components_name: $components_name"
    exit 1
    ;;
  esac
}

# 卸载服务（本地）
function components_uninstall() {
  case $components_name in
  all)
    eval $playboook_uninstall
    ;;
  redis)
    eval $playboook_uninstall -t uninstall_redis
    ;;
  mysql)
    eval $playboook_uninstall -t uninstall_mysql
    ;;
  tm)
    eval $playboook_uninstall -t uninstall_tm
    ;;
  ds)
    eval $playboook_uninstall -t uninstall_ds
    ;;
  dmz)
    eval $playboook_uninstall -t uninstall_dmz
    ;;
  data)
    eval $playboook_uninstall -t uninstall_data
    ;;
  app)
    eval $playboook_uninstall -t uninstall_app
    ;;
  *)
    echo "Invalid components_name: $components_name"
    exit 1
    ;;
  esac
}

# 主函数
function main() {
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
        conatainer_components_install
      fi
    elif [ "$action" == "uninstall" ]; then
      check_ansible_system
      if [ "$ansible_type" == "system" ]; then
        components_uninstall
      else
        conatainer_components_uninstall
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
