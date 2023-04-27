#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

echo -e "\n$CNT install gwenview qt5-imageformats  kimageformats ............................"
paru -S gwenview qt5-imageformats  kimageformats
sleep 2
echo -e "\n$CNT install dolphin ffmpegthumbs  kdegraphics-thumbnailers 	dolphin-plugins ............................"
paru -S dolphin ffmpegthumbs  kdegraphics-thumbnailers 	dolphin-plugins
sleep 2
echo -e "\n$CNT install ark p7zip unrar unarchiver ............................"
paru -S ark p7zip unrar unarchiver
sleep 2
echo -e "\n$CNT install kdeconnect sshfs  python-nautilus ............................"
paru -S kdeconnect sshfs  python-nautilus
sleep 2
echo -e "\n$CNT install v2ray v2raya docker docker-compose google-chrome kate ............................"
paru -S v2ray v2raya docker docker-compose google-chrome kate
sleep 2
echo -e "\n$CNT install goland goland-jre ............................"
paru -S goland goland-jre go rustup
sleep 2
echo -e "\n$CNT install virt-manager qemu-desktop dnsmasq iptables-nft samba ............................"
paru -S virt-manager qemu-desktop dnsmasq iptables-nft samba
sleep 2
echo -e "\n$CAC desktop done .................."
sleep 2

# user-dirs config
echo -e "\n$CNT starting config off user-dirs ............................"
sudo sed -i 's/enabled=True/enabled=False/' /etc/xdg/user-dirs.conf
sleep 2
echo -e "\n$CNT starting config user-dirs.dirs ........................"
cat > ~/.config/user-dirs.dirs  << EOF
XDG_DESKTOP_DIR="\$HOME/Desktop"
XDG_DOCUMENTS_DIR="\$HOME/Documents"
XDG_DOWNLOAD_DIR="\$HOME/Downloads"
XDG_MUSIC_DIR="\$HOME/Media/Music"
XDG_PICTURES_DIR="\$HOME/Media/Pictures"
XDG_PUBLICSHARE_DIR="\$HOME/Share"
XDG_TEMPLATES_DIR="\$HOME/Code"
XDG_VIDEOS_DIR="\$HOME/Media/Videos"
EOF
sleep 2
echo -e "\n$CNT starting config home directory ........................"
mkdir ~/Documents/go
mkdir ~/{Media,Code,Shared}
rm -rf ~/Templates/ ~/Public/
sleep 2
mv ~/Pictures/  ~/Music/  ~/Videos/  ~/Media/

# smb config
sleep 2
echo -e "\n$CNT starting config smb ........................"
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
sleep 2
sudo systemctl enable --now smb
sleep 2
read -rep $'[\e[1;37mATTENTION\e[0m] - Enter the smb password: ' SMBP
echo -e "${SMBP}\n${SMBP}" | sudo smbpasswd -a $USER

# docker config
sleep 2
echo -e "\n$CNT starting user join docker ........................"
sudo usermod -aG docker $USER
sleep 2

# bash config
echo -e "\n$CNT starting config bash ......................."
sed -i '/PS1=/d' ~/.bashrc
sleep 2
cat << EOF >> ~/.bashrc
parse_git_branch() {
     # git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1 )/'
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* [（头指针在 ]*\([0-9a-zA-Z+-\*/._=]*\)[ 分离）]*/ (\1 )/'
}
PS1='💻 \[\033[1;34m\]\t 📁 \[\033[1;32m\]\W\$(parse_git_branch) \[\033[1;31m\]\$ \[\033[00m\]'

export GOPATH='/home/liu/Documents/go'
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
EOF
sleep 2
source ~/.bashrc

# rust config
sleep 2
echo -e "\n$CNT starting config rust ........................"
rustup default stable
sleep 5
mkdir ~/.cargo
sleep 2
cat << EOF > ~/.cargo/config
[source.crates-io]
# To use sparse index, change 'rsproxy' to 'rsproxy-sparse'
replace-with = 'rsproxy'

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
EOF

# libvirt config
sleep 2
echo -e "\n$CNT starting config libvirt ........................"
sudo usermod -a -G libvirt $USER
sudo sh -c 'cat << EOF  > /etc/polkit-1/rules.d/80-libvirt.rules
polkit.addRule(function(action, subject) {
 if (action.id == "org.libvirt.unix.manage" && subject.local && subject.active && subject.isInGroup("libvirt")) {
 return polkit.Result.YES;
 }
});
EOF'
sleep 2
sudo systemctl enable --now libvirtd.service
sleep 2
sudo virsh net-autostart default
sleep 2

# setup v2raya
echo -e "\n$CNT starting setup v2raya ........................"
sudo systemctl enable --now v2raya
sleep 2

# setup blue
echo -e "\n$CNT starting setup blue ........................"
sudo systemctl enable --now bluetooth
sleep 2

echo -e "\n$COK ============================================\n"





