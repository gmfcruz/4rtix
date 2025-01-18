#!/bin/sh

clear

echo "s" | /usr/bin/pacman -Scc --noconfirm >/dev/null 2>&1
pacman -Sy artix-keyring --noconfirm >/dev/null 2>&1
pacman-key --populate artix >/dev/null 2>&1
pacman -Sy >/dev/null 2>&1

hash parted >/dev/null 2>&1 || pacman -S --noconfirm parted >/dev/null 2>&1
hash nvim >/dev/null 2>&1 || pacman -S --noconfirm neovim >/dev/null 2>&1

parted -s /dev/sda mklabel gpt
parted -s -a optimal /dev/sda mkpart "primary" "fat16" "0%" "512MiB"
parted -s /dev/sda set 1 esp on
parted -s /dev/sda align-check optimal 1
parted -s -a optimal /dev/sda mkpart "primary" "ext4" "512MiB" "100%"
parted -s /dev/sda set 2 lvm on

cryptsetup -v --cipher aes-xts-plain64 --key-size 256 --hash sha256 --iter-time 2000 --use-urandom --verify-passphrase luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 lvm-system

pvcreate /dev/mapper/lvm-system
vgcreate lvmSystem /dev/mapper/lvm-system
lvcreate -L 4G lvmSystem -n volSwap
lvcreate -l +100%FREE lvmSystem -n volRoot

mkswap /dev/lvmSystem/volSwap
mkfs.fat -n ESP /dev/sda1
mkfs.ext4 -L volRoot /dev/lvmSystem/volRoot

swapon /dev/lvmSystem/volSwap
mount /dev/lvmSystem/volRoot /mnt
mkdir -p /mnt/boot/EFI
mount /dev/sdX1 /mnt/boot/EFI

basestrap /mnt base base-devel

fstabgen -Up /mnt >> /mnt/etc/fstab

echo "tmpfs	/tmp	tmpfs	nodev,nosuid,size=2G	0 0" >> /mnt/etc/fstab

artools-chroot /mnt echo -e "pt_PT.UTF-8 UTF-8" >> /etc/locale.gen
artools-chroot /mnt  locale-gen
artools-chroot /mnt echo LANG=pt_PT.UTF-8 > /etc/locale.conf
artools-chroot /mnt export LANG=pt_PT.UTF-8

artools-chroot /mnt ln -s /usr/share/zoneinfo/Portugal /etc/localtime
artools-chroot /mnt echo "hostname=4rt1x" > /etc/conf.d/hostname

artools-chroot /mnt sed -i "s/FILES=(/FILES=(\/crypto_keyfile.bin/g" /etc/mkinitcpio.conf
artools-chroot /mnt sed -i "s/modconf block/modconf block encrypt lvm2 resume/g" /etc/mkinitcpio.conf

artools-chroot /mnt dd if=/dev/random of=/crypto_keyfile.bin bs=512 count=8 iflag=fullblock
artools-chroot /mnt cryptsetup luksAddKey /dev/sdX2 /crypto_keyfile.bin
artools-chroot /mnt chmod 000 /crypto_keyfile.bin

artools-chroot /mnt mkinitcpio -p linux

artools-chroot /mnt psswd

artools-chroot /mnt pacman -S --noconfimr grub efibootmgr dosfstools freetype2 fuse2 gptfdisk libisoburn mtools os-prober iw memtest86+ wpa_supplicant

artools-chroot /mnt sed -i "s/quiet/quiet resume=UUID=`blkid -s UUID -o value /dev/lvmSystem/volSwap`/g" /etc/default/grub

artools-chroot /mnt sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=`blkid -s UUID -o value /dev/sda2`:lvm-system\"/g" /etc/default/grub

artools-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=artix --recheck /dev/sda
artools-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

artools-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

pacman -S device-mapper-runit lvm2-runit cryptsetup-runit dbus-runit elogind cronie-runit

artools-chroot /mnt artools-chroot /mnt ln -sf /etc/runit/sv/dmeventd /etc/runit/runsvdir/default
artools-chroot /mnt ln -sf /etc/runit/sv/dbus /etc/runit/runsvdir/default
artools-chroot /mnt ln -sf /etc/runit/sv/cronie /etc/runit/runsvdir/default

artools-chroot /mnt pacman -S --noconfirm networkmanager networkmanager-openrc networkmanager-openvpn network-manager-applet

artools-chroot /mnt artools-chroot /mnt ln -sf /etc/runit/sv/networkmanager /etc/runit/runsvdir/default

artools-chroot /mnt wpa_passphrase "1PM4" "G0nc41oH31g4L30n0rL0v331nt3rn3t" > /etc/wpa_supplicant/wpa_supplicant.conf
artools-chroot /mnt echo "modules_INTERFACE_ID=\"wpa_supplicant dhcpcd\"" >> /etc/conf.d/net

artools-chroot /mnt echo "carrier_timeout_INTERFACE_ID=5" >> /etc/conf.d/net

artools-chroot /mnt pacman -S --noconfirm ntp-runit acpid-runit syslog-ng-runit

artools-chroot /mnt ln -sf /etc/runit/sv/ntpd /etc/runit/runsvdir/default
artools-chroot /mnt ln -sf /etc/runit/sv/acpid /etc/runit/runsvdir/default
artools-chroot /mnt ln -sf /etc/runit/sv/syslog-ng /etc/runit/runsvdir/default

artools-chroot /mnt pacman -S --noconfirm artools bash-completion lsof strace wget htop mc zip samba unrar p7zip unzip hdparm smartmontools hwinfo dmidecode whois rsync nmap tcpdump inetutils net-tools ndisc6

umount -R /mnt
swapoff -a
exit
