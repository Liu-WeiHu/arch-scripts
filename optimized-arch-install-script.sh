#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# 检查是否以root用户运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n$CER 请以root用户运行此脚本！"
    exit 1
fi

# 检查是否在安装环境中
IN_CHROOT=0
if [ -f /mnt/etc/fstab ] && ! [ -f /mnt/root/.chroot_completed ]; then
    echo -e "\n$CAT 检测到您可能已进入 chroot 环境。"
    read -rep $'是否继续执行 chroot 部分的安装流程？ (y/n) ' CONTINUE_CHROOT
    if [[ $CONTINUE_CHROOT == "Y" || $CONTINUE_CHROOT == "y" ]]; then
        IN_CHROOT=1
    else
        echo -e "\n$CER 脚本已终止！"
        exit 1
    fi
fi

# 主安装函数
main_install() {
    # 设置时间日期
    echo -e "\n$CNT 正在设置系统时间..."
    timedatectl set-ntp true
    timedatectl set-timezone Asia/Shanghai
    echo -e "\n$CAC 时间设置完成"

    # 询问分区
    echo -e "\n$CAT 请确认您已使用 cfdisk 完成磁盘分区，并已创建然后使用 lsblk 查看分区磁盘:"
    echo -e "   - EFI 分区 (建议 100MB)         举例：/dev/nvme0n1p1     /dev是固定的开头"
    echo -e "   - 根分区剩下的全部磁盘给根分区  举例：/dev/nvme0n1p2     /dev是固定的开头"
    read -rep $'确认已完成分区？ (y/n) ' PARTITION_CONFIRMED
    if [[ $PARTITION_CONFIRMED != "Y" && $PARTITION_CONFIRMED != "y" ]]; then
        echo -e "\n$CER 请先完成分区，然后再运行此脚本！"
        exit 1
    fi

    # 格式化分区
    read -rep $'请输入EFI分区的磁盘名比如：nvme0n1p1 不要有空格和斜杠 ' PARTITION_EFI
    read -rep $'请输入根分区的磁盘名比如：nvme0n1p2 不要有空格和斜杠 ' PARTITION_ROOT
    echo -e "\n$CNT 开始格式化分区..."
    mkfs.fat -F32 /dev/$PARTITION_EFI
    echo -e "\n$CAC EFI分区格式化完成"

    read -rep $'[\e[1;37mATTENTION\e[0m] - 是否需要使用RAID配置(单磁盘不需要)? (y/n) ' USE_RAID
    if [[ $USE_RAID == "Y" || $USE_RAID == "y" ]]; then
        read -rep $'请输入RAID配置参数 (例如: -d raid0 -m raid1): ' RAID_PARAMS
        mkfs.btrfs -f -L "MyArch" --checksum xxhash $RAID_PARAMS /dev/$PARTITION_ROOT
    else
        mkfs.btrfs -f -L "MyArch" --checksum xxhash /dev/$PARTITION_ROOT
    fi
    echo -e "\n$CAC 根分区格式化完成"

    # 创建子卷
    echo -e "\n$CNT 创建 Btrfs 子卷..."
    mount /dev/$PARTITION_ROOT /mnt

    btrfs sub create /mnt/@
    btrfs sub create /mnt/@cache
    btrfs sub create /mnt/@log
    btrfs sub create /mnt/@swap

    read -rep $'[\e[1;37mATTENTION\e[0m] - 是否创建独立的 home 子卷? (y/n) ' CREATE_HOME
    if [[ $CREATE_HOME == "Y" || $CREATE_HOME == "y" ]]; then
        btrfs sub create /mnt/@home
        MOUNT_HOME=1
    else
        MOUNT_HOME=0
    fi

    umount /mnt
    echo -e "\n$CAC 子卷创建完成"

    # 挂载文件系统
    echo -e "\n$CNT 开始挂载文件系统..."
    mount -o noatime,ssd,compress-force=zstd,nodiscard,subvol=@ /dev/$PARTITION_ROOT /mnt
    echo -e "\n$CAC 根分区挂载完成"

    mkdir -p /mnt/efi
    mount /dev/$PARTITION_EFI /mnt/efi
    echo -e "\n$CAC EFI分区挂载完成"

    if [ $MOUNT_HOME -eq 1 ]; then
        mkdir -p /mnt/home
        mount -o noatime,ssd,compress-force=zstd,nodiscard,subvol=@home /dev/$PARTITION_ROOT /mnt/home
        echo -e "\n$CAC home分区挂载完成"
    fi

    mkdir -p /mnt/var/cache
    mount -o noatime,ssd,compress-force=zstd,nodiscard,subvol=@cache /dev/$PARTITION_ROOT /mnt/var/cache
    echo -e "\n$CAC cache分区挂载完成"

    mkdir -p /mnt/var/log
    mount -o noatime,ssd,compress-force=zstd,nodiscard,subvol=@log /dev/$PARTITION_ROOT /mnt/var/log
    echo -e "\n$CAC log分区挂载完成"

    mkdir -p /mnt/swap
    mount -o defaults,subvol=@swap /dev/$PARTITION_ROOT /mnt/swap
    echo -e "\n$CAC swap分区挂载完成"

    lsblk
    sleep 3

    # 配置镜像源
    echo -e "\n$CNT 配置镜像源..."
    pacman -Sy --noconfirm
    pacman -Rsnu reflector --noconfirm || true

    cat >/etc/pacman.d/mirrorlist <<EOF
Server=https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server=https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
EOF
    echo -e "\n$CAC 镜像源配置完成"

    # 安装基本系统
    echo -e "\n$CNT 开始安装基本系统..."
    pacstrap /mnt base base-devel linux linux-firmware btrfs-progs neovim networkmanager pacman-contrib
    echo -e "\n$CAC 基本系统安装完成"

    # 生成 fstab
    echo -e "\n$CNT 生成 fstab..."
    genfstab -U /mnt >/mnt/etc/fstab
    echo -e "\n$CAC fstab 生成完成"

    # 准备 chroot
    echo -e "\n$CNT 准备 chroot 环境..."

    # 创建自检文件
    touch /mnt/root/.first_stage_completed

    # 复制脚本到安装环境
    if [ -d "$(dirname "$0")" ]; then
        cp -r "$(dirname "$0")" /mnt/root/arch-scripts
    else
        mkdir -p /mnt/root/arch-scripts
        cp "$0" /mnt/root/arch-scripts/
    fi

    chmod +x /mnt/root/arch-scripts/*.sh

    # 自动进入 chroot 环境并继续安装
    echo -e "\n$CNT 自动进入 chroot 环境并继续安装..."
    arch-chroot /mnt /bin/bash -c "cd /root/arch-scripts && bash $(basename "$0")"

    # 如果 chroot 执行成功
    if [ -f /mnt/root/.chroot_completed ]; then
        echo -e "\n$COK 安装已完成，可以重启进入新系统了"
        echo -e "\n$CAT 请执行以下命令重启系统:"
        echo -e "    umount -R /mnt"
        echo -e "    reboot"
    else
        echo -e "\n$CER chroot 阶段可能未完成，请检查错误并手动完成安装"
    fi
}

# chroot 安装函数
chroot_install() {
    echo -e "\n$CNT 进入 chroot 环境，开始系统配置..."

    # 更新系统
    echo -e "\n$CNT 更新软件包数据库..."
    pacman -Syy

    # 设置时区
    echo -e "\n$CNT 设置时区..."
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc
    echo -e "\n$CAC 时区设置完成"

    # 设置 nvim 别名
    read -rep $'[\e[1;37mATTENTION\e[0m] - 是否添加 nvim -> vi 软链接? (y/n) ' NVIM
    if [[ $NVIM == "Y" || $NVIM == "y" ]]; then
        echo -e "$CNT 设置 nvim 别名..."
        ln -sf /usr/bin/nvim /usr/bin/vi
        echo -e "\n$CAC nvim 别名设置完成"
    fi

    # 设置语言
    echo -e "\n$CNT 设置系统语言..."
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >/etc/locale.conf
    echo -e "\n$CAC 系统语言设置完成"

    # 设置网络
    echo -e "\n$CNT 设置网络..."
    read -rep $'[\e[1;37mATTENTION\e[0m] - 请输入主机名 (默认: Arch): ' HOSTNAME
    HOSTNAME=${HOSTNAME:-Arch}
    echo "$HOSTNAME" >/etc/hostname

    cat >/etc/hosts <<EOF
127.0.0.1       localhost
::1             localhost
127.0.1.1       $HOSTNAME.localdomain $HOSTNAME
EOF
    echo -e "\n$CAC 网络设置完成"

    # 设置 initramfs
    echo -e "\n$CNT 配置 initramfs..."
    sed -i '/^HOOKS=/s/.$/ systemd&/' /etc/mkinitcpio.conf
    mkinitcpio -P
    echo -e "\n$CAC initramfs 配置完成"

    # 设置 root 密码
    echo -e "\n$CNT 设置 root 密码..."
    read -rep $'[\e[1;37mATTENTION\e[0m] - 请输入 root 密码: ' PASSWD
    echo -e "${PASSWD}\n${PASSWD}" | passwd root
    echo -e "\n$CAC root 密码设置完成"

    # 设置 fstrim
    read -rep $'[\e[1;37mATTENTION\e[0m] - 是否开启 fstrim 服务? (y/n) ' FSTRIM
    if [[ $FSTRIM == "Y" || $FSTRIM == "y" ]]; then
        echo -e "\n$CNT 开启 fstrim 服务..."
        systemctl enable fstrim.timer
        echo -e "\n$CAC fstrim 服务已开启"
    fi

    # 安装微码
    echo -e "\n$CNT 安装 CPU 微码，请选择 CPU 类型..."
    select name in "cpu-intel" "cpu-amd"; do
        case $name in
        "cpu-intel")
            pacman -S --noconfirm intel-ucode
            CPU_TYPE="intel"
            break
            ;;
        "cpu-amd")
            pacman -S --noconfirm amd-ucode
            CPU_TYPE="amd"
            break
            ;;
        *)
            echo "输入错误，请重新输入"
            ;;
        esac
    done
    echo -e "\n$CAC CPU 微码安装完成"

    # 安装并配置 GRUB
    echo -e "\n$CNT 安装配置 GRUB..."
    pacman -S --noconfirm grub efibootmgr

    read -rep $'[\e[1;37mATTENTION\e[0m] - 是否探测其他操作系统? (y/n) ' PROBE
    if [[ $PROBE == "Y" || $PROBE == "y" ]]; then
        echo -e "$CNT 配置 OS 探测器..."
        sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        pacman -S --noconfirm os-prober
        echo -e "\n$CAC OS 探测器配置完成"
    fi

    # 优化 GRUB 配置
    sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"' /etc/default/grub
    sed -i 's/GRUB_GFXMODE=auto/GRUB_GFXMODE=1280x1024/' /etc/default/grub

    # 安装 GRUB
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch --boot-directory=/efi
    grub-mkconfig -o /efi/grub/grub.cfg
    echo -e "\n$CAC GRUB 安装配置完成"

    # 启用网络服务
    echo -e "\n$CNT 启用网络服务..."
    systemctl enable NetworkManager
    echo -e "\n$CAC 网络服务已启用"

    # 标记 chroot 安装完成
    touch /root/.chroot_completed

    echo -e "\n$COK chroot 部分配置完成! 即将继续执行用户配置脚本..."

    # 自动执行用户配置脚本
    bash /root/arch-scripts/user-configure-script.sh
}

# 根据环境执行不同的安装函数
if [ $IN_CHROOT -eq 1 ]; then
    chroot_install
elif [ -f /root/.first_stage_completed ]; then
    chroot_install
else
    main_install
fi
