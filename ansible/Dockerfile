FROM ubuntu:20.04

# ADD ./sources.list /etc/apt/sources.list

RUN apt update \
    && apt install ansible sshpass vim net-tools -y \
    && apt autoremove -y \
    && rm -rf /var/cache/apt/archives/ \
    && sed -i "/^\[defaults\]/a\log_path = ./ansible.log" /etc/ansible/ansible.cfg \
    && touch /etc/ansible/ansible.log

WORKDIR /data

CMD ["tail", "-f", "/etc/ansible/ansible.log"]
