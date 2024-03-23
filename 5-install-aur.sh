#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# docker config
echo -e "\n$CNT starting config docker filesystem ................"
sudo systemctl enable --now docker
sleep 2
sudo mkdir /etc/docker
sleep 2
sudo sh -c 'cat << EOF > /etc/docker/daemon.json
{
"storage-driver": "btrfs"
}
EOF'
sleep 2
sudo systemctl restart docker
sleep 2
echo -e "\n$CWR check docker filesystem is btrfs ..............."
docker info | grep Storage
sleep 5

# aur install
paru -S linuxqq visual-studio-code-bin dbeaver-ee wireshark-qt
sleep 2

# setup wireshark config
sudo gpasswd -a $USER wireshark


# v2raya 配置
# 域名查询服务器
# 182.254.116.116->direct
# tcp://dns.alidns.com:53->direct

# 223.5.5.5 -> direct
# 119.29.29.29 -> direct

# 国外域名查询服务器
# 8.8.4.4:53->proxy
# tcp://1.0.0.1:53->proxy
# tcp://dns.opendns.com:5353->proxy

# 8.8.4.4 -> proxy
# tcp://dns.opendns.com:5353 -> proxy

echo -e "\n$COK ============================================\n"