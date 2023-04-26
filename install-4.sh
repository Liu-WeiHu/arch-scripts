#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# install desktop
echo -e "\n$CNT install plasma-meta yakuake ...........................\n"
paru -S plasma-meta yakuake
sleep 1

# install wayland
read -rep $'[\e[1;33mACTION\e[0m] - Are you install wayland desktop? (y,n) ' KEY
if [[ $KEY == "Y" || $KEY == "y" ]]; then
    echo -e "$CNT - Setup starting install wayland .................\n"
    paru -S sddm-git plasma-wayland-session  xdg-desktop-portal  xdg-desktop-portal-gtk
    echo -e "\n$CAC wayland done .................\n"
    sleep 1
    sudo sh -c 'cat << EOF  > /etc/sddm.conf.d/10-wayland.conf
[General]
DisplayServer=wayland
GreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell

[Wayland]
CompositorCommand=kwin_wayland --no-lockscreen --inputmethod maliit-keyboard
EOF'
else
    echo -e "$CNT - Setup starting install x11 .................\n"
    paru -S sddm
    echo -e "\n$CAC x11 done .................\n"
fi
sleep 1

sudo systemctl enable sddm
reboot

echo -e "\n$CNT install spectacle kate ...........................\n"
paru -S spectacle kate
sleep 1
echo -e "\n$CNT install gwenview qt5-imageformats  kimageformats ...........................\n"
paru -S gwenview qt5-imageformats  kimageformats
sleep 1
echo -e "\n$CNT install dolphin ffmpegthumbs  kdegraphics-thumbnailers 	dolphin-plugins ...........................\n"
paru -S dolphin ffmpegthumbs  kdegraphics-thumbnailers 	dolphin-plugins
sleep 1
echo -e "\n$CNT install ark p7zip unrar unarchiver ...........................\n"
paru -S ark p7zip unrar unarchiver
sleep 1
echo -e "\n$CNT install kdeconnect sshfs  python-nautilus ...........................\n"
paru -S kdeconnect sshfs  python-nautilus
sleep 1
echo -e "\n$CNT install v2ray v2raya docker docker-compose google-chrome ...........................\n"
paru -S v2ray v2raya docker docker-compose google-chrome
sleep 1
echo -e "\n$CNT install goland goland-jre ...........................\n"
paru -S goland goland-jre go rustup
sleep 1
echo -e "\n$CNT install virt-manager qemu-desktop dnsmasq iptables-nft samba ...........................\n"
paru -S virt-manager qemu-desktop dnsmasq iptables-nft samba
sleep 1
echo -e "\n$CAC desktop done .................\n"
sleep 1

# fix config
echo -e "\n$CNT starting fix config ...........................\n"
sed -i 's/enabled=True/enabled=False/' /etc/xdg/user-dirs.conf
sleep 1
cat > ~/.config/user-dirs.dirs  << EOF
XDG_DESKTOP_DIR="$HOME/Desktop"
XDG_DOCUMENTS_DIR="$HOME/Documents"
XDG_DOWNLOAD_DIR="$HOME/Downloads"
XDG_MUSIC_DIR="$HOME/Media/Music"
XDG_PICTURES_DIR="$HOME/Media/Pictures"
XDG_PUBLICSHARE_DIR="$HOME/Share"
XDG_TEMPLATES_DIR="$HOME/Code"
XDG_VIDEOS_DIR="$HOME/Media/Videos"
EOF
sleep 1
sudo sh -c 'cat << EOF  > /etc/samba/smb.conf
[Shared]
        comment = Shared Folder for QEMU
        path = /home/liu/Shared
        public = yes
        valid users = liu
        browseable = yes
        writeable = yes
        read only = no
        security = user
        passdb backend = tdbsam
        force user = liu
[global]
        server min protocol = NT1
        lanman auth = yes
        ntlm auth = yes
EOF'
sleep 1
sudo systemctl enable --now smb
sleep 1
sudo systemctl enable --now v2raya
sleep 1
sudo usermod -aG docker $USER
newgrp docker
sleep 1
sudo systemctl enable --now libvirtd.service
sleep 1
sed -i '/PS1=/d' ~/.bashrc
sleep 1
cat << EOF >> ~/.bashrc
parse_git_branch() {
     # git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1 )/'
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* [（头指针在 ]*\([0-9a-zA-Z+-\*/._=]*\)[ 分离）]*/ (\1 )/'
}
PS1='💻 \[\033[1;34m\]\t 📁 \[\033[1;32m\]\W$(parse_git_branch) \[\033[1;31m\]$ \[\033[00m\]'

export GOPATH='/home/liu/Documents/go'
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
EOF
sleep 1
source .bashrc
sleep 1
rustup default stable
sleep 1
groupadd libvirt
sudo usermod -a -G libvirt $USER
sudo sh -c 'cat << EOF  > /etc/polkit-1/rules.d/80-libvirt.rules
polkit.addRule(function(action, subject) {
 if (action.id == "org.libvirt.unix.manage" && subject.local && subject.active && subject.isInGroup("libvirt")) {
 return polkit.Result.YES;
 }
});
EOF'
sleep 1

echo -e "\n$COK ============================================\n"





