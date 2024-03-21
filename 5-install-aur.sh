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

# setup wayland config
read -rep $'[\e[1;37mATTENTION\e[0m] - Are you setup wayland config? (y,n) ' WAYLANDC
if [[ $WAYLANDC == "Y" || $WAYLANDC == "y" ]]; then
echo -e "$CNT - Setup starting config electron wayland .................."
cat << EOF > ~/.config/electron-flags.conf
--enable-features=UseOzonePlatform
--ozone-platform-hint=auto
--ignore-gpu-blocklist
--enable-features=WaylandWindowDecorations
--enable-gpu-rasterization
--enable-zero-copy
--enable-wayland-ime
--disable-gpu-driver-bug-workarounds
--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks
--disable-features=UseChromeOSDirectVideoDecoder
--enable-webrtc-pipewire-capturer
EOF
sleep 2
echo -e "$CNT - Setup starting config java wayland .................."
mkdir ~/.config/environment.d
cat > ~/.config/environment.d/env.conf << EOF
_JAVA_AWT_WM_NONREPARENTING=1
MOZ_ENABLE_WAYLAND=1
BROWSER=firefox
EOF
fi

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