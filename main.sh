#!/bin/bash

# set some colors
CNT="[\e[1;36mNOTE\e[0m]"
COK="[\e[1;32mOK\e[0m]"
CER="[\e[1;31mERROR\e[0m]"
CAT="[\e[1;37mATTENTION\e[0m]"
CWR="[\e[1;35mWARNING\e[0m]"
CAC="[\e[1;33mACTION\e[0m]"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "\n$CER Please run this script as root!"
    exit 1
fi

# Check if in chroot environment
IN_CHROOT=0
if [ -f /mnt/etc/fstab ] && ! [ -f /mnt/root/.chroot_completed ]; then
    echo -e "\n$CAT Detected you may have entered the chroot environment."
    read -rep $'Continue with the chroot part of the installation? (y/n) ' CONTINUE_CHROOT
    if [[ $CONTINUE_CHROOT == "Y" || $CONTINUE_CHROOT == "y" ]]; then
        IN_CHROOT=1
    else
        echo -e "\n$CER Script terminated!"
        exit 1
    fi
fi

# Main installation function
main_install() {
    # Set date and time
    echo -e "\n$CNT Setting up system time..."
    timedatectl set-ntp true
    timedatectl set-timezone Asia/Shanghai
    echo -e "\n$CAC Time setup completed"

    # Ask about partitioning
    echo -e "\n$CAT Please confirm you have completed disk partitioning with cfdisk and created then viewed partitions with lsblk:"
    echo -e "   - EFI partition (recommended 100MB)     Example: /dev/nvme0n1p1     /dev is the fixed prefix"
    echo -e "   - Root partition with remaining space   Example: /dev/nvme0n1p2     /dev is the fixed prefix"
    read -rep $'Confirm partitioning is completed? (y/n) ' PARTITION_CONFIRMED
    if [[ $PARTITION_CONFIRMED != "Y" && $PARTITION_CONFIRMED != "y" ]]; then
        echo -e "\n$CER Please complete partitioning first, then run this script!"
        exit 1
    fi

    # Format partitions
    read -rep $'Please enter the EFI partition name (e.g. nvme0n1p1) without spaces or slashes: ' PARTITION_EFI
    read -rep $'Please enter the root partition name (e.g. nvme0n1p2) without spaces or slashes: ' PARTITION_ROOT
    echo -e "\n$CNT Starting partition formatting..."
    mkfs.fat -F32 /dev/$PARTITION_EFI
    echo -e "\n$CAC EFI partition formatting completed"

    read -rep $'[\e[1;37mATTENTION\e[0m] - Do you need RAID configuration (not needed for single disk (default: n) )? (y/n) ' USE_RAID
    USE_RAID=${USE_RAID:-n}
    if [[ $USE_RAID == "Y" || $USE_RAID == "y" ]]; then
        read -rep $'Please enter RAID parameters (e.g.: -d raid0 -m raid1): ' RAID_PARAMS
        mkfs.btrfs -f -L "MyArch" --checksum xxhash $RAID_PARAMS /dev/$PARTITION_ROOT
    else
        mkfs.btrfs -f -L "MyArch" --checksum xxhash /dev/$PARTITION_ROOT
    fi
    echo -e "\n$CAC Root partition formatting completed"

    # Create subvolumes
    echo -e "\n$CNT Creating Btrfs subvolumes..."
    mount /dev/$PARTITION_ROOT /mnt

    btrfs sub create /mnt/@
    btrfs sub create /mnt/@cache
    btrfs sub create /mnt/@log
    btrfs sub create /mnt/@swap

    read -rep $'[\e[1;37mATTENTION\e[0m] - Create separate home subvolume (default: n)? (y/n) ' CREATE_HOME
    CREATE_HOME=${CREATE_HOME:-n}
    if [[ $CREATE_HOME == "Y" || $CREATE_HOME == "y" ]]; then
        btrfs sub create /mnt/@home
        MOUNT_HOME=1
    else
        MOUNT_HOME=0
    fi

    umount /mnt
    echo -e "\n$CAC Subvolume creation completed"

    # Mount filesystems
    echo -e "\n$CNT Mounting filesystems..."
    mount -o noatime,ssd,compress-force=zstd,nodiscard,subvol=@ /dev/$PARTITION_ROOT /mnt
    echo -e "\n$CAC Root partition mounted"

    mkdir -p /mnt/efi
    mount /dev/$PARTITION_EFI /mnt/efi
    echo -e "\n$CAC EFI partition mounted"

    if [ $MOUNT_HOME -eq 1 ]; then
        mkdir -p /mnt/home
        mount -o noatime,ssd,compress-force=zstd,nodiscard,subvol=@home /dev/$PARTITION_ROOT /mnt/home
        echo -e "\n$CAC Home partition mounted"
    fi

    mkdir -p /mnt/var/cache
    mount -o noatime,ssd,compress-force=zstd,nodiscard,subvol=@cache /dev/$PARTITION_ROOT /mnt/var/cache
    echo -e "\n$CAC Cache partition mounted"

    mkdir -p /mnt/var/log
    mount -o noatime,ssd,compress-force=zstd,nodiscard,subvol=@log /dev/$PARTITION_ROOT /mnt/var/log
    echo -e "\n$CAC Log partition mounted"

    mkdir -p /mnt/swap
    mount -o defaults,subvol=@swap /dev/$PARTITION_ROOT /mnt/swap
    echo -e "\n$CAC Swap partition mounted"

    lsblk
    sleep 3

    # Configure mirrors
    echo -e "\n$CNT Configuring mirrors..."
    pacman -Sy --noconfirm
    pacman -Rsnu reflector --noconfirm || true

    cat >/etc/pacman.d/mirrorlist <<EOF
Server=https://mirrors.ustc.edu.cn/archlinux/\$repo/os/\$arch
Server=https://mirrors.tuna.tsinghua.edu.cn/archlinux/\$repo/os/\$arch
EOF
    echo -e "\n$CAC Mirrors configuration completed"

    # Install base system
    echo -e "\n$CNT Installing base system..."
    pacstrap /mnt base base-devel linux linux-firmware btrfs-progs neovim networkmanager pacman-contrib
    echo -e "\n$CAC Base system installation completed"

    # Generate fstab
    echo -e "\n$CNT Generating fstab..."
    genfstab -U /mnt >/mnt/etc/fstab
    echo -e "\n$CAC fstab generation completed"

    # Prepare chroot
    echo -e "\n$CNT Preparing chroot environment..."

    # Create checkpoint file
    touch /mnt/root/.first_stage_completed

    # Copy script to installation environment
    if [ -d "$(dirname "$0")" ]; then
        cp -r "$(dirname "$0")" /mnt/root/arch-scripts
    else
        mkdir -p /mnt/root/arch-scripts
        cp "$0" /mnt/root/arch-scripts/
    fi

    chmod +x /mnt/root/arch-scripts/*.sh

    # Automatically enter chroot environment and continue installation
    echo -e "\n$CNT Automatically entering chroot environment to continue installation..."
    arch-chroot /mnt /bin/bash -c "cd /root/arch-scripts && bash $(basename "$0")"

    # If chroot execution successful
    if [ -f /mnt/root/.chroot_completed ]; then
        echo -e "\n$COK Installation completed, you can now reboot into your new system"
        echo -e "\n$CAT Please execute the following commands to reboot:"
        echo -e "    umount -R /mnt"
        echo -e "    reboot"
    else
        echo -e "\n$CER Chroot stage may not have been completed, please check for errors and manually complete the installation"
    fi
}

# Chroot installation function
chroot_install() {
    echo -e "\n$CNT Entered chroot environment, beginning system configuration..."

    # Update system
    echo -e "\n$CNT Updating package database..."
    pacman -Syy

    # Set timezone
    echo -e "\n$CNT Setting timezone..."
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    hwclock --systohc
    echo -e "\n$CAC Timezone setup completed"

    # Set nvim alias
    read -rep $'[\e[1;37mATTENTION\e[0m] - Add nvim -> vi symlink (default: y)? (y/n) ' NVIM
    NVIM=${NVIM:-y}
    if [[ $NVIM == "Y" || $NVIM == "y" ]]; then
        echo -e "$CNT Setting nvim alias..."
        ln -sf /usr/bin/nvim /usr/bin/vi
        echo -e "\n$CAC nvim alias setup completed"
    fi

    # Set language
    echo -e "\n$CNT Setting system language..."
    sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sed -i 's/#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >/etc/locale.conf
    echo -e "\n$CAC System language setup completed"

    # Set network
    echo -e "\n$CNT Setting up network..."
    read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter hostname (default: Arch): ' HOSTNAME
    HOSTNAME=${HOSTNAME:-Arch}
    echo "$HOSTNAME" >/etc/hostname

    cat >/etc/hosts <<EOF
127.0.0.1       localhost
::1             localhost
127.0.1.1       $HOSTNAME.localdomain $HOSTNAME
EOF
    echo -e "\n$CAC Network setup completed"

    # Set initramfs
    echo -e "\n$CNT Configuring initramfs..."
    sed -i '/^HOOKS=/s/.$/ systemd&/' /etc/mkinitcpio.conf
    mkinitcpio -P
    echo -e "\n$CAC initramfs configuration completed"

    # Set root password
    echo -e "\n$CNT Setting root password..."
    read -rep $'[\e[1;37mATTENTION\e[0m] - Please enter root password: ' PASSWD
    echo -e "${PASSWD}\n${PASSWD}" | passwd root
    echo -e "\n$CAC Root password setup completed"

    # Set fstrim
    echo -e "\n$CNT Enabling fstrim service..."
    systemctl enable fstrim.timer
    echo -e "\n$CAC fstrim service enabled"

    # Install microcode
    echo -e "\n$CNT Installing CPU microcode, please select CPU type..."
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
            echo "Invalid input, please try again"
            ;;
        esac
    done
    echo -e "\n$CAC CPU microcode installation completed"

    # Install and configure GRUB
    echo -e "\n$CNT Installing and configuring GRUB..."
    pacman -S --noconfirm grub efibootmgr

    read -rep $'[\e[1;37mATTENTION\e[0m] - Detect other operating systems (default: n)? (y/n) ' PROBE
    PROBE=${PROBE:-n}
    if [[ $PROBE == "Y" || $PROBE == "y" ]]; then
        echo -e "$CNT Configuring OS prober..."
        sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
        pacman -S --noconfirm os-prober
        echo -e "\n$CAC OS prober configuration completed"
    fi

    # Optimize GRUB configuration
    sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3"' /etc/default/grub
    sed -i 's/GRUB_GFXMODE=auto/GRUB_GFXMODE=1280x1024/' /etc/default/grub

    # Install GRUB
    grub-install --target=x86_64-efi --efi-directory=/efi --bootloader-id=Arch --boot-directory=/efi
    grub-mkconfig -o /efi/grub/grub.cfg
    echo -e "\n$CAC GRUB installation and configuration completed"

    # Enable network service
    echo -e "\n$CNT Enabling network service..."
    systemctl enable NetworkManager
    echo -e "\n$CAC Network service enabled"

    # Mark chroot installation as completed
    touch /root/.chroot_completed

    echo -e "\n$COK Chroot configuration completed! Continuing to user configuration script..."

    # Automatically execute user configuration script
    bash /root/arch-scripts/main_sub.sh
}

# Execute different installation functions based on environment
if [ $IN_CHROOT -eq 1 ]; then
    chroot_install
elif [ -f /root/.first_stage_completed ]; then
    chroot_install
else
    main_install
fi
