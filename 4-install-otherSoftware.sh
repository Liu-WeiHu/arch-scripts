#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

echo -e "\n$CNT install gwenview dolphin............................"
paru -S gwenview dolphin
sleep 2
echo -e "\n$CNT install ark 7-zip-full unrar unarchiver ............................"
paru -S ark 7-zip-full unrar unarchiver
sleep 2
echo -e "\n$CNT install v2ray v2raya docker docker-compose google-chrome kate firefox obs-studio libreoffice-still ............................"
paru -S v2ray v2raya docker docker-compose chromium kate firefox obs-studio libreoffice-still libreoffice-still-zh-cn
sleep 2
echo -e "\n$CAC desktop done .................."
sleep 2

# goland install
read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install goland ? (y,n) ' GOLAND
if [[ $GOLAND == "Y" || $GOLAND == "y" ]]; then
echo -e "$CNT - Setup starting install goland goland-jre go rustup ..................."
paru -S goland goland-jre go rustup
sleep 2
echo -e "\n$CAC goland done ..................."
fi

# clion install 
read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install clion ? (y,n) ' CLION
if [[ $CLION == "Y" || $CLION == "y" ]]; then
echo -e "$CNT - Setup starting install goland goland-jre go rustup ..................."
paru -S clion clion-cmake clion-gdb clion-jre clion-lldb
sleep 2
echo -e "\n$CAC clion done ..................."
fi

# kvm qemu install
read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install virt-manager qemu ? (y,n) ' QEMU
if [[ $QEMU == "Y" || $QEMU == "y" ]]; then
echo -e "$CNT - Setup starting install virt-manager qemu-full dnsmasq iptables-nft samba ..................."
paru -S virt-manager qemu-desktop dnsmasq iptables-nft samba
sleep 2

# smb config
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
sleep 2

# celluloid 配置
# echo -e "\n$CNT starting config celluloid ........................"
# mkdir ~/.config/mpv
# cat > ~/.config/mpv/mpv.conf << EOF
# hwdec=vulkan,vaapi
# gpu-hwdec-interop=vaapi
# EOF

# libvirt config
sleep 2
echo -e "\n$CNT starting config libvirt ........................"
sudo usermod -a -G libvirt $USER
sudo sh -c 'cat << EOF  > /etc/polkit-1/rules.d/50-libvirt.rules
polkit.addRule(function(action, subject) {
if (action.id == "org.libvirt.unix.manage" &&
subject.isInGroup("libvirt")) {
return polkit.Result.YES;
}
});
EOF'
sleep 2
sudo systemctl enable --now libvirtd.service
sleep 2
sudo virsh net-autostart default

# configure qemu
sudo sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/s/.$/ qxl bochs_drm&/' /etc/default/grub
sudo grub-mkconfig -o /efi/grub/grub.cfg

# end
sleep 2
echo -e "\n$CAC virt-manager qemu done ..................."
fi

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
PS1='░▒▓\e[30;47;1m  \e[37;45m \w$(parse_git_branch)\e[0m\e[35m\e[0m\e[1C'

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
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
EOF
sleep 2

# setup v2raya
echo -e "\n$CNT starting setup v2raya ........................"
sudo systemctl enable --now v2raya
sleep 2

# setup blue
echo -e "\n$CNT starting setup blue ........................"
sudo systemctl enable --now bluetooth
sleep 2

# setup xrandr
read -rep $'[\e[1;37mATTENTION\e[0m] - Are you install xrandr and configure it? (y,n) ' XRANDR
if [[ $XRANDR == "Y" || $XRANDR == "y" ]]; then
echo -e "$CNT - Setup starting install xrandr and configure ..................."
paru -S xorg-xrandr
sleep 2
sudo sh -c 'cat << EOF >> /usr/share/sddm/scripts/Xsetup
intern=eDP-1
extern1=DP-1-1
extern2=DP-1-2
xrandr=\$(xrandr)
output=
if [[ "\$xrandr" =~ "\$extern1 connected" ]]; then
output=\$extern1
elif [[ "\$xrandr" =~ "\$extern2 connected" ]]; then
output=\$extern2
fi

if [[ -n "\$output" ]]; then
xrandr --output "\$intern" --off --output "\$output" --auto
else
xrandr --output "\$intern" --auto
fi
EOF'
sleep 2
echo -e "\n$CAC xrandr done ..................."
fi
sleep 2

# disable startup discover
cp /etc/xdg/autostart/org.kde.discover.notifier.desktop  ~/.config/autostart/
sleep 1
echo Hidden=True >> ~/.config/autostart/org.kde.discover.notifier.desktop
sleep 2
echo -e "\n$CAC disable startup discover done ..................."

echo -e "\n$COK ============================================\n"
