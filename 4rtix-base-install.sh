#!/bin/sh

clear
set -xe

runuser - root 'echo "y" | /usr/bin/pacman -Scc --noconfirm >/dev/null 2>&1'
runuser - root "pacman -Sy artix-keyring --noconfirm >/dev/null 2>&1"
runuser - root "pacman-key --populate artix >/dev/null 2>&1"
runuser - root "pacman -Sy >/dev/null 2>&1"

runuser - root "hash parted >/dev/null 2>&1 || pacman -S --noconfirm parted >/dev/null 2>&1"
runuser - root "hash nvim >/dev/null 2>&1 || pacman -S --noconfirm neovim >/dev/null 2>&1"

runuser - root "parted -s /dev/vda mklabel msdos"
runuser - root 'parted -s -a optimal /dev/vda mkpart "primary" "ext4" "0%" "100%"'
runuser - root "parted -s /dev/vda set 1 boot on"
runuser - root "parted -s /dev/vda set 1 lvm on"
runuser - root "parted -s /dev/vda align-check optimal 1"

runuser - root "cryptsetup -v --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 10000 --use-urandom --verify-passphrase luksFormat /dev/vda1"
runuser - root "cryptsetup luksOpen /dev/vda1 lvm-system"

runuser - root "pvcreate /dev/mapper/lvm-system"
runuser - root "vgcreate lvmSystem /dev/mapper/lvm-system"

runuser - root "lvcreate --contiguous y --size 250M lvmSystem --name volBoot"
runuser - root "lvcreate --contiguous y --size 2G lvmSystem --name volSwap"
runuser - root "lvcreate --contiguous y --extents +100%FREE lvmSystem --name volRoot"

runuser - root "mkfs.fat -n BOOT /dev/lvmSystem/volBoot"
runuser - root "mkswap -L SWAP /dev/lvmSystem/volSwap"
runuser - root "mkfs.ext4 -L ROOT /dev/lvmSystem/volRoot"

runuser - root "swapon /dev/lvmSystem/volSwap"
runuser - root "mount /dev/lvmSystem/volRoot /mnt"
runuser - root "mount --mkdir /dev/lvmSystem/volBoot /mnt/boot"

runuser - root 'sed -i -e "s/    prepare_bootloader(fw_type)/    return None/g" /usr/lib/calamares/modules/bootloader/main.py'

runuser - root 'sed -i "s/\-gpt/\- gpt\n\    -vmd/" /etc/calamares/modules/partition.conf'
runuser - root 'sed -i "s/\-gpt/\- gpt\n\    -vmd/" /etc/calamares-offline/modules/partition.conf'
runuser - root 'sed -i "s/\-gpt/\- gpt\n\    -vmd/" /etc/calamares-online/modules/partition.conf'

(cd /mnt) &
(cd /mnt/boot) &

calamares-config-switcher && runuser - root 'sed -i -n -e "/^#/p" /mnt/etc/fstab'

runuser - root "fstabgen -Up /mnt > /mnt/etc/fstab"
runuser - root 'sed -i -n -e "/^#/p" /mnt/etc/fstab'

runuser - root 'echo -e "tmpfs\t/tmp\ttmpfs\trw,nosuid,nodev,relatime,size=1G,mode=1777\t0\t0" >> /mnt/etc/fstab'

runuser - root "artix-chroot /mnt passw"

runuser - root 'echo -e "pt_PT.UTF-8 UTF-8" >> /mnt/etc/locale.gen'
runuser - root "artix-chroot /mnt locale-gen"
runuser - root 'echo "LANG=pt_PT.UTF-8" > /mnt/etc/locale.conf'
# export "LANG=pt_PT.UTF-8"
runuser - root 'echo "LC_ADDRESS=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
runuser - root 'echo "LC_IDENTIFICATION=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
runuser - root 'echo "LC_MEASUREMENT=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
runuser - root 'echo "LC_MONETARY=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
runuser - root 'echo "LC_NAME=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
runuser - root 'echo "LC_NUMERIC=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
runuser - root 'echo "LC_PAPER=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
runuser - root 'echo "LC_TELEPHONE=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
runuser - root 'echo "LC_TIME=pt_PT.UTF-8" >> /mnt/etc/locale.conf'
# echo "LC_COLLATE=C" >> /mnt/etc/locale.conf
# export LC_COLLATE="C"

runuser - root "artix-chroot /mnt ln -sf /usr/share/zoneinfo/Portugal /etc/localtime"

runuser - root 'echo "hostname=\"4rt1x\"" > /mnt/etc/conf.d/hostname'

runuser - root 'sed -s 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block encrypt keyboard keymap lvm2 resume filesystems fsck usr)/g' -i /mnt/etc/mkinitcpio.conf'
 
runuser - root "artix-chroot /mnt pacman -Rc --noconfirm artix-grub-theme"
runuser - root "artix-chroot /mnt pacman -Rc --noconfirm linux linux-headers"
runuser - root "artix-chroot /mnt pacman -S --noconfirm linux-hardened linux-hardened-headers"
runuser - root "artix-chroot /mnt pacman -S --noconfirm openssl openssl-1.1 pacman lvm2 cryptsetup nano glibc mkinitcpio"
runuser - root "artix-chroot /mnt mkinitcpio -p linux-hardened"
runuser - root "artix-chroot /mnt pacman -S --noconfirm grub"

cryptuuid=$(blkid -s UUID -o value /dev/vda1)
swapuuid=$(blkid -s UUID -o value /dev/lvmSystem/volSwap)
runuser - root 'sed -s "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"\'
runuser - root "cryptdevice=UUID=${cryptuuid}:lvm-system loglevel=3 quiet resume=UUID=${swapuuid} net.ifnames=0 lsm=lockdown,yama,apparmor,bpf\"/g" -i /mnt/etc/default/grub"
runuser - root 'sed -s "s/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g" -i /mnt/etc/default/grub'
 
runuser - root "artix-chroot /mnt pacman -S --noconfirm dosfstools freetype2 fuse2 gptfdisk libisoburn mtools os-prober iw memtest86+ wpa_supplicant device-mapper-runit lvm2-runit cryptsetup-runit havged-runit cronie-runit gcr networkmanager networkmanager-runit networkmanager-openvpn network-manager-applet ntp-runit acpid-runit syslog-ng-runit artools lsof strace wget htop mc zip unrar p7zip unzip hdparm smartmontools hwinfo dmidecode whois rsync nmap inetutils net-tools ndisc6 apparmor-runit dbus-runit"

 runuser - root "artix-chroot /mnt ln -sf /etc/runit/sv/dmeventd /etc/runit/runsvdir/current"
 runuser - root "artix-chroot /mnt ln -sf /etc/runit/sv/dbus /etc/runit/runsvdir/current"
 runuser - root "artix-chroot /mnt ln -sf /etc/runit/sv/haveded /etc/runit/runsvdir/current"
 runuser - root "artix-chroot /mnt ln -sf /etc/runit/sv/cronie /etc/runit/runsvdir/current"
 runuser - root "artix-chroot /mnt ln -sf /etc/runit/sv/ntpd /etc/runit/runsvdir/current"
 runuser - root "artix-chroot /mnt ln -sf /etc/runit/sv/acpid /etc/runit/runsvdir/current"

 runuser - root "artix-chroot /mnt grub-install --target=i386-pc --boot-directory=/boot --bootloader-id=artix --recheck /dev/vda"

 runuser - root "artix-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg"

 runuser - root "umount -R /mnt"
 runuser - root "swapoff -a"
 runuser - root "sync"
exit
