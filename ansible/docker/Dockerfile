# 使用更小的基础镜像
FROM ubuntu:20.04

# 减少层数，优化命令合并
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ansible \
    sshpass \
    vim \
    net-tools \
    python3-pip && \
    pip3 install --no-cache-dir requests tabulate wcwidth && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/* && \
    sed -i "/^\[defaults\]/a\log_path = ./ansible.log" /etc/ansible/ansible.cfg && \
    touch /etc/ansible/ansible.log

# 设置工作目录
WORKDIR /data

# 容器启动命令
CMD ["tail", "-f", "/etc/ansible/ansible.log"]
