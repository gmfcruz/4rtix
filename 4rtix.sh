#!/bin/sh
#
# Gonçalo Cruz: 4rtix.sh,v x.x.x 2025/XX/XX XX:XX:XX 
#
# Copyright (C) 2024 Gonçalo Cruz (link)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

clear

#
########################################################################################
#
# Variables/Parameters 
#
########################################################################################
#
machine="desktop"					# Machine Role [desktop/server/vm]
hstname="localhost"					# System Hostname
cvg="crypt-lvm"						# Name for the crypted volume
user="user"						# Default Username
userpass="123foo"					# Default User password
loc="Portugal"						# Location
lang="pt_PT"						# Language
keymp="pt-latin1"					# Keymap
pkg="yay"						# AUR Helper
memo="4"						# Memory installed
ssid=""							# SSID name wifi
wfpass=""						# Wifi password
wfcon=""						# Wifi connection for connmand software
xorg="1"						# Xorg	[0=False/1=QXL]	(vm)
							#	[0=False/1=Intel/2=NVIDIA]

case $(grep vendor /proc/cpuinfo) in
*"Intel"*)
	ucode="intel-ucode"
	;;
*"Amd"*)
	ucode="amd-ucode"
	;;
esac

tlp_conf="https://raw.githubusercontent.com/kyau/dotfiles/master/system/etc/default/tlp"

#
########################################################################################
#
# Proper usage checks.
#
########################################################################################
#

[ -z "$1" ] && echo 'Usage: 
Install_script /dev/sdX "password if you want system encryption"' && exit
# [ -z "$(ls /sys/firmware/efi/efivars)" ] &&
# 	echo "EFI only installation; Please boot with EFI." && exit
[ $(id -u) != 0 ] && echo "Root privileges required." && exit
[ -z "$(connmanctl state | grep -e online -e ready)" ] && \
	echo "No network connection." && exit

#
########################################################################################
#
# Target Disk and encryption password parameters.
#
########################################################################################
#

targetdisk=$1
[ -z "$targetdisk" ] && echo "No target disk specified." && exit
cryptpass=$2
# [ -z "$cryptpass" ] && echo "No encryption password provided." && exit
[ -z "$cryptpass" ] && crypt=0 || crypt=1

#
########################################################################################
#
# If variables was not inserted on this file.
#
########################################################################################
#

until [ "$machine" ]; do
	echo -e "\nWhat type is this machine: [desktop/vm/server]: " && read -r machine
	[ ! "$machine" ] && machine="desktop"
done

until [ "$cvg" ]; do
	echo -e "\nName to the encrypted volume: " && read -r cvg
	[ ! "$cvg" ] && cvg="crypt-lvm"
done

until [ "$user" ]; do
	echo -e "\nName to the encrypted volume: " && read -r user 
	[ ! "$user" ] && user="gmfcruz"
done

until [ "$userpass" ]; do
	echo -e "\nUser Password: " && read -r userpass
	[ ! "$userpass" ] && userpass="gmfcruz1234"
done

until [ "$loc" ]; do
	echo -e "\nRegion/City [e.g. Portugal/Lisbon]: " && read -r loc
	[ ! "$loc" ] && loc="Portugal/Lisbon"
done

until [ "$lang" ]; do
	echo -e "\nLanguage [e.g. "pt_PT" for Portuguese]: " && read -r lang
	[ ! "$lang" ] && lang="pt_PT"
done

until [ "$keymp" ]; do
	echo -e "\nKeyMap [e.g. "pt-latin1" for Portuguese keyboard layout]: " && read -r keymp
	[ ! "$keymp" ] && keymp="pt-latin1"
done

until [ "$pkg" ]; do
	echo -e "\nAUR Helper [e.g. yay/pikaur]: " && read -r pkg
	[ ! "$pkg" ] && pkg="pt_PT"
done

until [ "$memo" ]; do
	echo -e "\nMemory installed [e.g. 4]: " && read -r memo
	[ ! "$memo" ] && memo="2"
done

until [ "$ssid" ]; do
	echo -e "\nName of wifi network [SSID]: " && read -r ssid
	[ ! "$ssid" ] && ssid="1PM4n"
done

until [ "$wfpass" ]; do
	echo -e "\nWifi password: " && read -r wfpass
	[ ! "$wfpass" ] && wfpass="123foo"
done

# until [ "$wfcon" ]; do
# 	echo -e "\nName of wifi connection for connman: " && read -r wfcon
# 	[ ! "$wfcon" ] && wfcon="123foo"
# done

until [ "$xorg" ]; do
	echo -e "\nXorg (0-2) [Default 0]: " && read -r xorg
	[ ! "$xorg" ] && xorg="0"
done

until [ "$hstname" ]; do
	echo -e "\nHostname: " && read -r hstname
	[ ! "$hstname" ] && hash dmidecode >/dev/null 2>&1 || pacman -S dmidecode --noconfirm >/dev/null 2>&1 &&
		hstname="$(dmidecode -s system-product-name)"
done
clear

#
########################################################################################
#
# Install needed software
#
########################################################################################
#

echo "s" | /usr/bin/pacman -Scc --noconfirm >/dev/null 2>&1
/usr/bin/pacman -Sy artix-keyring --noconfirm >/dev/null 2>&1
/usr/bin/pacman-key --populate artix >/dev/null 2>&1
/usr/bin/pacman -Sy >/dev/null 2>&1
hash git	>/dev/null 2>&1	|| pacman -S git 	--noconfirm >/dev/null 2>&1
hash nvim	>/dev/null 2>&1 || pacman -S neovim 	--noconfirm >/dev/null 2>&1
hash parted 	>/dev/null 2>&1 || pacman -S parted 	--noconfirm >/dev/null 2>&1
hash wipefs 	>/dev/null 2>&1 || pacman -S wipefs 	--noconfirm >/dev/null 2>&1
hash sgdisk 	>/dev/null 2>&1 || pacman -S gptfdisk 	--noconfirm >/dev/null 2>&1
hash wget	>/dev/null 2>&1 || pacman -S wget	--noconfirm >/dev/null 2>&1

echo "+## Installation Parameters ##+"
echo "Target disk   : \"$targetdisk\""
[ $crypt -eq "1" ] && echo "Crypto pass   : \"$cryptpass\""
echo "Machine Role:\"$machine\""
echo "Username:\"$user\""
echo "Username password:\"$userpass\""
echo "Region/City: \"$loc\""
echo "Language: \"$lang\""
echo "KeyMap: \"$keymp\""
echo "AUR Helper: \"$pkg\""
echo "SSID Wifi: \"$ssid\""
echo "Wifi password: \"$wfpass\""
# echo "Wifi connmand connection: \"$wfcon\""
echo "Xorg: \"$xorg\"[0=False/1=QXL]	(vm)
		     [0=False/1=Intel/2=NVIDIA]"
echo "Instaled memory: \"$memo\""
echo "CPU Microcode: \"$ucode\""
echo "Hostname: \"$hstname\""
echo -n "Correct?" && read

#
########################################################################################
#
# Reset/init.
#
########################################################################################
#

grep -q "/mnt" <<< $(mount) && umount -R /mnt
[ -h /dev/$cvg/swap ] && swapoff -a 
/usr/bin/pvremove -y -ff $targetdisk
/usr/bin/dmsetup remove_all
cryptsetup close cryptlvm
killall -s 9 cryptsetup

#
########################################################################################
#
# Wipe disk.
#
########################################################################################
#

echo "Do you want to wipe the disk $targetdisk? [y/n]:" && read -r  wdisk
[ "${wdisk}" = "y" ] &&
	/usr/bin/wipefs -af $targetdisk && (/usr/bin/dd if=/dev/zero of=$targetdisk bs=1k count=2048) && 
 	[ -d /sys/firmware/efi ] && /usr/bin/sgdisk -Z -o $targetdisk

#
########################################################################################
#
# Clean/write disk.
#
########################################################################################
#

echo "Do you want to Clean with blocks of zero the entire disk? [y/n]:" && read -r clndisk
[ "$clndisk" = "y" ] &&
	(/usr/bin/dd bs=1M if=/dev/zero iflag=nocache of=$targetdisk oflag=direct status=progress || true) && sync

if [ "$crypt" -eq "1" ]; then
	echo "Do you want to write random blocks on entire disk? [y/n]:" && read -r rdisk
	[ "$rdisk" = "y" ] &&
		(/usr/bin/dd bs=1M if=/dev/random iflag=nocache of=$targetdisk oflag=direct status=progress || true) && sync
fi

#
########################################################################################
#
# Partition the disk.
#
########################################################################################
#

set -xe
if [ $crypt -eq "1" ]; then
	parted -s -a optimal $targetdisk mklabel gpt
	parted -s -a optimal $targetdisk mkpart "BOOT" fat32 0% 512MiB
	parted -s -a optimal $targetdisk set 1 esp on
	parted -s -a optimal $targetdisk mkpart "CRYPT" ext4 512MiB 100%
	parted -s -a optimal $targetdisk set 2 lvm on
else
	if [ -d /sys/firmware/efi ]; then
		# Procurar saber se é esta a extrutura 
		parted -s -a optimal $targetdisk mklabel gpt
		parted -s -a optimal $targetdisk mkpart "BOOT" fat32 0% 512MiB
		parted -s -a optimal $targetdisk set 1 boot on
		parted -s -a optimal $targetdisk mkpart "LVM" ext4 512MiB 100%
		parted -s -a optimal $targetdisk set 2 lvm on
	else
		parted -s -a optimal $targetdisk mklabel mbr
		parted -s -a optimal $targetdisk set 1 boot on
		parted -s -a optimal $targetdisk mkpart "LVM" ext4 0% 100%
	fi
fi

#
########################################################################################
#
# Set up LUKS encrypted container.
#
########################################################################################
#

if [ $crypt -eq "1" ]; then
	echo -ne "$cryptpass" | cryptsetup -v -q -c aes-xts-plain64 --key-size 512 --hash whirlpool --iter-time 10000 --pbkdf argon2i --use-random luksFormat ${targetdisk}2 -d -
	echo -ne "$cryptpass" | cryptsetup open ${targetdisk}2 cryptlvm -d -
fi

#
########################################################################################
#
# Create logical volumes.
#
########################################################################################
#

swp=$((${memo}+1))

[ $crypt -eq "1" ] && pvcreate /dev/mapper/cryptlvm || pvcreate ${targetdisk}2
[ $crypt -eq "1" ] && vgcreate $cvg /dev/mapper/cryptlvm || vgcreate $cvg ${targetdisk}2
lvcreate -L $swp"G" $cvg -n swap
lvcreate -L 512M $cvg -n root
lvcreate -L 10G $cvg -n usr
lvcreate -L 512M $cvg -n var
lvcreate -L 10G $cvg -n var_cache
lvcreate -L 512M $cvg -n var_log
lvcreate -L 512M $cvg -n var_log_audit
lvcreate -l 100%FREE $cvg -n home

#
########################################################################################
#
# Make filesystems.
#
########################################################################################
#

[ -d /sys/firmware/efi ] && mkfs.fat -F32 ${targetdisk}1 || mke2fs -t ext4 -qF ${targetdisk}1
mkswap -f /dev/$cvg/swap && swapon /dev/$cvg/swap
mke2fs -t ext4 -qF -O ^metadata_csum -O ^has_journal /dev/$cvg/root
mke2fs -t ext4 -qF -O ^metadata_csum -O ^has_journal /dev/$cvg/usr
mke2fs -t ext4 -qF -O ^metadata_csum -O ^has_journal /dev/$cvg/var
mke2fs -t ext4 -qF -O ^metadata_csum -O ^has_journal /dev/$cvg/var_cache
mke2fs -t ext4 -qF -O ^metadata_csum -O ^has_journal /dev/$cvg/var_log
mke2fs -t ext4 -qF -O ^metadata_csum -O ^has_journal /dev/$cvg/var_log_audit
mke2fs -t ext4 -qF -O ^metadata_csum -O ^has_journal /dev/$cvg/home

#
########################################################################################
#
# Mount filesystems.
#
########################################################################################
#

mount -o defaults,noatime /dev/$cvg/root /mnt
[ -d /sys/firmware/efi ] && mount -m "${targetdisk}"1 /mnt/boot || mount -m "${targetdisk}"1 /mnt/boot
mount -o defaults,noatime -m /dev/$cvg/usr /mnt/usr
mount -o defaults,noatime,nosuid -m /dev/$cvg/var /mnt/var
mount -o defaults,noatime,nodev,nosuid -m /dev/$cvg/var_cache /mnt/var/cache
mount -o defaults,noatime,nodev,noexec,nosuid -m /dev/$cvg/var_log /mnt/var/log
mount -o defaults,noatime,nodev,noexec,nosuid -m /dev/$cvg/var_log_audit /mnt/var/log/audit
mount -o defaults,noatime,nodev,nosuid -m /dev/$cvg/home /mnt/home

#
########################################################################################
#
# Basestrap the system and install lvm hooks.
#
########################################################################################
#

# _basestrap_remove=(linux pyalpm)
_basestrap=(base base-devel runit elogind elogind-runit linux-lts linux-firmware haveged haveged-runit backlight-runit libpwquality sysstat rsync-runit nfs-utils nfs-utils-runit neovim ntp ntp-runit acpi acpid-runit dmidecode udiskie less mlocate device-mapper device-mapper-runit openssl metalog metalog-runit firejail ntfs-3g logrotate lvm2 man-db man-pages usbguard usbguard-runit apparmor apparmor-runit tlp tlp-runit bind cronie cronie-runit git wget)
# Virualization
_basestrap+=(virt-manager libvirt-runit qemu dnsmasq-runit bridge-utils openbsd-netcat vde2)
# Encryption
[ "$crypt" = 1 ] && _basestrap+=(cryptsetup)
# UEFI/MBR
[ -d /sys/firmware/efi ] && _basestrap+=(grub gptfdisk efibootmgr) || _basestrap+=(grub)
## Firewall 
_basestrap+=(nftables nftables-runit)
[ -n ${ssid} ] && _basestrap+=(wpa_supplicant wpa_supplicant-runit connman connman-runit networkmanager networkmanager-runit networkmanager-openvpn network-manager-applet iw)
# pacman / aur helper
_basestrap+=(pacman-contrib pyalpm)
# audit 
_basestrap+=(audit audit-runit)
# compression
_basestrap+=(p7zip unrar)
# terminal, shell
_basestrap+=(zsh)
# microcode , xorg and audio
_basestrap+=(${ucode})
# Xorg
[ ${xorg} -ne "0" ] && _basestrap+=(alsa-utils pulseaudio-alsa)
[ ${xorg} -eq "1" ] && _basestrap+=(libva-intel-driver mesa-vdpau vdpauinfo vulkan-intel)
[ ${xorg} -eq "2" ] && _basestrap+=(mesa-vdpau nvidia-dkms nvidia-settings vdpauinfo)
basestrap "/mnt" "${_basestrap[@]}"  

#
########################################################################################
#
# Config mount points
#
########################################################################################
#

fstabgen -pU /mnt > /mnt/etc/fstab
# [ -d /sys/firmware/efi ] && /usr/bin/sed -i 's/rw,relatime,fmask/ro,noatime,nodev,noexec,nosuid,fmask/' /mnt/etc/fstab
# [ ! -d /sys/firmware/efi ] && /usr/bin/sed -i 's/rw,relatime,stripe=4/ro,noatime,nodev,noexec,nosuid,stripe=4/' /mnt/etc/fstab
# /usr/bin/sed -i 's/rw,noatime\t0 1/defaults,noatime\t0 1/' /mnt/etc/fstab
# /usr/bin/sed -i 's/\/var[\t ]*ext4[\t ]*rw/\/var\t\text4\t\trw,nodev/' /mnt/etc/fstab
# echo -e "# /dev: device nodes\ndevtmpfs\t/dev\tdevtmpfs\tdefaults,noexec,nosuid\t0 0\n\n# /dev/shm: shared application memory\ntmpfs\t/dev/shm\ttmpfs\tdefaults,noatime,nodev,nosuid,noexec,size=1024M,mode=1770,uid=root,gid=shm\t0 0\n" >> /mnt/etc/fstab
# echo -e "# /tmp: temporary files\ntmpfs\t/tmp\t\ttmpfs\tdefaults,noatime,nodev,noexec,nosuid,size=8192M,mode=1777\t0 0\n" >> /mnt/etc/fstab
# echo -e "# /var/tmp: temporary files (preserved)\n/tmp\t/var/tmp\tnone\tdefaults,noatime,nodev,noexec,nosuid,bind\t0 0\n" >> /mnt/etc/fstab
# echo -e "# /var/cache/makepkg: temporary build dir\ntmpfs\t/var/cache/makepkg\t\ttmpfs\tdefaults,noatime,nodev,nosuid,size=4096M,mode=1770,uid=root,gid=wheel\t0 0\n" >> /mnt/etc/fstab
# [ ${xorg} -ne "0" ] && echo -e "# /proc: kernel and process information\nproc\t/proc\t\tproc\tnodev,noexec,nosuid,gid=wheel\t0 0" >> /mnt/etc/fstab || echo -e "# /proc: kernel and process information\nproc\t/proc\t\tproc\tnodev,noexec,nosuid,hidepid=2,gid=wheel\t0 0" >> /mnt/etc/fstab

## testar
/usr/bin/sed -i 's/rw,relatime,stripe=4/ro,noatime,nodev,noexec,nosuid,stripe=4/' /mnt/etc/fstab
/usr/bin/sed -i 's/rw,noatime\t0 1/defaults,noatime\t0 1/' /mnt/etc/fstab
echo -e "# /dev/shm: shared application memory\ntmpfs\t/dev/shm\ttmpfs\tdefaults,noatime,nodev,nosuid,noexec,size=$(($memo/2))G,mode=1771,uid=root,gid=shm\t0 0\n" >> /mnt/etc/fstab
echo -e "# /tmp: temporary files\ntmpfs\t/tmp\t\ttmpfs\tdefaults,noatime,nodev,noexec,nosuid,size=8192M,mode=1777\t0 0\n" >> /mnt/etc/fstab
echo -e "# /var/tmp: temporary files (preserved)\n/tmp\t/var/tmp\tnone\tdefaults,noatime,nodev,noexec,nosuid,bind\t0 0\n" >> /mnt/etc/fstab
echo -e "# /var/cache/makepkg: temporary build dir\ntmpfs\t/var/cache/makepkg\t\ttmpfs\tdefaults,noatime,nodev,nosuid,size=4096M,mode=1771,uid=root,gid=wheel\t0 0\n" >> /mnt/etc/fstab
echo -e "# /proc: kernel and process information\nproc\t/proc\t\tproc\tnodev,noexec,nosuid,gid=wheel\t0 0" >> /mnt/etc/fstab

#
########################################################################################
#
# Remove linux kernel
#
########################################################################################
#

# /usr/bin/artix-chroot /mnt pacman -Rc --noconfirm linux linux-headers
# /usr/bin/artix-chroot /mnt pacman -S --noconfirm linux-hardened linux-hardened-headers
# /usr/bin/artix-chroot /mnt pacman -S --noconfirm openssl openssl-1.1 pacman

#
########################################################################################
#
# Hooks for mkinicpio
#
########################################################################################
#

sed -s 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block \
encrypt keyboard keymap lvm2 resume filesystems fsck usr)/g' -i /mnt/etc/mkinitcpio.conf

#
########################################################################################
#
# Install and configure grub.
#
########################################################################################
#

basestrap /mnt mkinitcpio
cryptuuid=$(blkid -s UUID -o value ${targetdisk}2)
swapuuid=$(blkid -s UUID -o value /dev/$cvg/swap)
sed -s "s/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"\
cryptdevice=UUID=${cryptuuid}:lvm-system quiet loglevel=3 resume=UUID=${swapuuid} net.ifnames=0 lsm=lockdown,yama,apparmor,bpf\"/g" \
	-i /mnt/etc/default/grub
sed -s 's/^#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/g' -i /mnt/etc/default/grub
/usr/bin/sed -i "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/" /mnt/etc/default/grub
/usr/bin/sed -i "s/#GRUB_COLOR_NORMAL/GRUB_COLOR_NORMAL/g" /mnt/etc/default/grub
/usr/bin/sed -i "s/#GRUB_COLOR_HIGHLIGHT/GRUB_COLOR_HIGHLIGHT/g" /mnt/etc/default/grub
	
	# Block grub and settings
GRUB_PASSWD=$(echo -e "${userpass}\n${userpass}\n" | /mnt/usr/sbin/grub-mkpasswd-pbkdf2 | tail -n 1 | cut -d ' ' -f 7)
/usr/bin/cat > /mnt/etc/grub.d/05_superusers << EOL
cat << EOF
set superusers="${user}"
password_pbkdf2 ${user} ${GRUB_PASSWD}
EOF
EOL
chmod 0700 /mnt/etc/grub.d/05_superusers
/usr/bin/sed -i "s/ \${CLASS} / \${CLASS} --users \'\' /" /mnt/etc/grub.d/10_linux
if [ -d /sys/firmware/efi ]; then
	artix-chroot /mnt sh -c 'grub-install --target=x86_64-efi --efi-directory=/boot \
--bootloader-id=grub && grub-mkconfig -o /boot/grub/grub.cfg'
else
	/usr/bin/partprobe $targetdisk
	/usr/bin/artix-chroot /mnt grub-install --target=i386-pc ${targetdisk}
fi

#
########################################################################################
#
# Set locale, default timezone and keymap.
#
########################################################################################
#

/usr/bin/sed -i "s/^#${lang}\.UTF/${lang}\.UTF/" /mnt/etc/locale.gen
/usr/bin/sed -i 's/^en_US\.UTF/#en_US\.UTF/' /mnt/etc/locale.gen
/usr/bin/artix-chroot /mnt locale-gen
/usr/bin/cat > /mnt/etc/locale.conf << EOF
LANG=${lang}.UTF-8
LC_ADDRESS=${lang}.UTF-8
LC_IDENTIFICATION=${lang}.UTF-8
LC_MONETARY=${lang}.UTF-8
LC_NAME=${lang}.UTF-8
LC_NUMERIC=${lang}.UTF-8
LC_PAPER=${lang}.UTF-8
LC_TELEPHONE=${lang}.UTF-8
LC_TIME=${lang}.UTF-8
LC_COLLATE=${lang}.UTF-8
EOF
# /usr/bin/artix-chroot /mnt export "LANG=pt_PT.UTF-8"
# /usr/bin/artix-chroot /mnt export LC_COLLATE="C" 
/usr/bin/cat > /mnt/etc/vconsole.conf <<EOF
#!/bin/env
kbd_mode -u
KEYMAP=${keymp}
FONT=lat0-16
EOF
artix-chroot /mnt ln -sf /usr/share/zoneinfo/${loc} /etc/localtime 
artix-chroot /mnt hwclock -w

#
########################################################################################
#
# Install tlp
#
########################################################################################
#

/usr/bin/wget "${tlp_conf}" -O /mnt/etc/default/tlp

#
########################################################################################
#
# Install archlinux support
#
########################################################################################
#

/usr/bin/cat <<EOT >> /mnt/etc/pacman.conf

#
# Custom
#

# Artix

[universe]
Server = https://universe.artixlinux.org/\$arch
Server = https://mirror1.artixlinux.org/universe/\$arch
Server = https://mirror.pascalpuffke.de/artix-universe/\$arch
Server = https://artixlinux.qontinuum.space/artixlinux/universe/os/\$arch
Server = https://mirror1.cl.netactuate.com/artix/universe/\$arch
Server = https://ftp.crifo.org/artix-universe/
EOT

artix-chroot /mnt pacman -Sy --needed --noconfirm artix-archlinux-support 

/usr/bin/cat <<EOT >> /mnt/etc/pacman.conf

# Arch

#[testing]
#Include = /etc/pacman.d/mirrorlist-arch

[extra]
Include = /etc/pacman.d/mirrorlist-arch

#[community-testing]
#Include = /etc/pacman.d/mirrorlist-arch

[community]
Include = /etc/pacman.d/mirrorlist-arch

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist-arch

#[multilib]
#Include = /etc/pacman.d/mirrorlist-arch
EOT
artix-chroot /mnt pacman-key --populate archlinux
artix-chroot /mnt pacman -Sy --noconfirm grml-zsh-config arch-audit

#
########################################################################################
#
# lock root account, set user and sudoers.
#
########################################################################################
#

_rootpass=$(openssl rand -hex 16)
artix-chroot /mnt chpasswd <<< "root:${_rootpass}"
/usr/bin/cat > /mnt/root/IDp << EOF
${_rootpass}
EOF
/usr/bin/artix-chroot /mnt runuser -l root -c "chage -M -1 root"
/usr/bin/artix-chroot /mnt runuser -l root -c "chage -M 1460 -m 1 -W 20 ${user}"
artix-chroot /mnt passwd -l root
/usr/bin/cat > /mnt/etc/sudoers.d/$user << EOF
Defaults editor=/usr/bin/nvim
# %wheel ALL=(ALL:ALL) ALL
%wheel ALL=(ALL) ALL
EOF
/usr/bin/artix-chroot /mnt runuser -l root -c "chsh -s /usr/bin/zsh"
artix-chroot /mnt useradd -m -s /usr/bin/zsh "${user}"
/usr/bin/artix-chroot /mnt runuser -l root -c "rm -rf /home/${user}/.bash*"
artix-chroot /mnt usermod -a -G kvm,libvirt,video,audio,wheel "${user}"
artix-chroot /mnt chpasswd <<< "${user}:${userpass}"
 /usr/bin/sed -i "s/GETTY_ARGS=\"--noclear\"/GETTY_ARGS=\"--autologin ${user} --noclear\"/g" /mnt/etc/runit/sv/agetty-tty1/conf
/usr/bin/artix-chroot /mnt groupadd shm
/usr/bin/artix-chroot /mnt gpasswd -a ${user} shm 

echo -e "${user} ALL=(ALL) NOPASSWD: ALL\n" > /mnt/etc/sudoers.d/temporary

/usr/bin/artix-chroot /mnt runuser -l "${user}" -c "git clone https://aur.archlinux.org/${pkg}.git"
/usr/bin/artix-chroot /mnt runuser -l "${user}" -c "cd ${pkg} && makepkg -fsr --noconfirm"
T_PKGAUR=$(/usr/bin/artix-chroot /mnt ls /home/${user}/${pkg}/ | /usr/bin/grep .pkg.tar.zst)
/usr/bin/artix-chroot /mnt pacman -U "/home/${user}/${pkg}/${T_PKGAUR}" --noconfirm
/usr/bin/artix-chroot /mnt runuser -l "${user}" -c "rm -rf /home/${user}/${pkg}"

/usr/bin/artix-chroot /mnt yay -S rkhunter pkg-audit lesspipe --noconfirm

/usr/bin/rm -rf /mnt/etc/sudoers.d/temporary

/usr/bin/cat >> /mnt/home/"${user}"/.zshrc.local << EOF
eval '\$(SHELL=/bin/sh lesspipe.sh) >/dev/null 2>&1'
export LESS='-R'
export PYGMENTIZE_STYLE='paraiso-dark'
EOF
/usr/bin/artix-chroot /mnt runuser -l root -c "chown ${user}:${user} /home/${user}/.zshrc.local"

#
########################################################################################
#
# Security Features
#
########################################################################################
#

echo "write-cache" >> /mnt/etc/apparmor/parser.conf
echo "FAILLOG_ENAB\t\tyes" >> /mnt/etc/login.defs

/usr/bin/cat > /mnt/etc/pam.d/passwd << EOF
password required pam_cracklib.so retry=2 difok=6 minlen=12 dcredit=-1 ucredit=-1 lcredit=-1 ocredit=-1 maxrepeat=2 maxsequence=4 reject_username
password required pam_unix.so use_authtok shadow sha512 rounds=65535
EOF

/usr/bin/sed -i "s/active = no/active = yes/" /mnt/etc/audit/plugins.d/syslog.conf
/usr/bin/sed -i -e 's/^PASS_MAX_DAYS\t99999/PASS_MAX_DAYS\t1460/' /mnt/etc/login.defs
/usr/bin/sed -i -e 's/^PASS_MIN_DAYS\t0/PASS_MIN_DAYS\t1/' /mnt/etc/login.defs
/usr/bin/sed -i -e 's/#SHA_CRYPT_MIN_ROUNDS 5000/SHA_CRYPT_MIN_ROUNDS 655360/' /mnt/etc/login.defs
/usr/bin/sed -i -e 's/#SHA_CRYPT_MAX_ROUNDS 5000/SHA_CRYPT_MAX_ROUNDS 655360/' /mnt/etc/login.defs
/usr/bin/sed -i "s/^UMASK/UMASK/\t\t027/" /mnt/etc/login.defs
/usr/bin/sed -i "s/umask 022/umask 027/" /mnt/etc/profile
/usr/bin/sed -i "s/^#auth           required        pam_wheel.so use_uid/auth\t\trequired\tpam_wheel.so use_uid/" /mnt/etc/pam.d/su
/usr/bin/sed -i "s/^#auth           required        pam_wheel.so use_uid/auth\t\trequired\tpam_wheel.so use_uid/" /mnt/etc/pam.d/su-l
/usr/bin/sed -i "s/# If not running/umask 027\n\n# If not running/" /mnt/etc/bash/bashrc
/usr/bin/sed -i "s/#Color/Color/" /mnt/etc/pacman.conf
/usr/bin/sed -i "s/#CacheDir    = \/var\/cache\/pacman\/pkg\//CacheDir = \/var\/cache\/makepkg\//" /mnt/etc/pacman.conf

if [ -d /sys/firmware/efi ]; then
	/usr/bin/artix-chroot /mnt runuser -l root -c "chmod -R go-rwx /root /home/${user} /boot"
else
	/usr/bin/artix-chroot /mnt runuser -l root -c "chmod -R go-rwx /root /home/${user}"
	/usr/bin/artix-chroot /mnt runuser -l root -c "chmod go-rwx /boot"
fi
/usr/bin/artix-chroot /mnt runuser -l root -c "chmod 600 /etc/sudoers.d/${user}"

artix-chroot /mnt mkdir -p /etc/sysctl.d
/usr/bin/cat > /mnt/etc/sysctl.d/50-security.conf << EOF
dev.tty.ldisc_autoload=0
fs.protected_fifos=2
fs.protected_regular=2
fs.suid_dumpable=0
kernel.dmesg_restrict=1
kernel.kptr_restrict=2
kernel.sysrq=0
kernel.unprivileged_bpf_disabled=1
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.log_martians=1
net.ipv4.conf.default.secure_redirects=0
net.ipv4.conf.default.send_redirects=0
net.ipv4.conf.all.send_redirects=0
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_rfc1337=1
EOF

## Blacklist Kernel Modules
/usr/bin/cat > /mnt/etc/modprobe.d/blacklist.conf << EOF
install affs /bin/false
install befs /bin/false
#install cifs /bin/false
install coda /bin/false
install cramfs /bin/false
install firewire-core /bin/false
install hfs /bin/false
install hfsplus /bin/false
install jfs /bin/false
install jffs2 /bin/false
install kafs /bin/false
install mtd /bin/false
install nilfs2 /bin/false
install ocfs2 /bin/false
install omfs /bin/false
install orangefs /bin/false
install overlay /bin/false
#install reiserfs /bin/false
install romfs /bin/false
install squashfs /bin/false
install ubifs /bin/false
install udf /bin/false
install usb-storage /bin/false
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
EOF

# echo -e "EDITOR=/usr/bin/nvim\nSUDO_EDITOR=/usr/bin/nvim" >> /mnt/root/.bashrc
echo -e "EDITOR=/usr/bin/nvim\nSUDO_EDITOR=/usr/bin/nvim" >> /mnt/root/.zshrc.local

/usr/bin/cat > /mnt/etc/issue << EOF
Atention, by continuing to connect to this system,
you consent to the owner storing a log of all activity.

Unauthorized access to this system is prohibited
Press <Ctrl-D> if you are not an authorized user
EOF
/usr/bin/cp -f /mnt/etc/issue /mnt/etc/issue.net
/usr/bin/chmod 644 /mnt/etc/issue /mnt/etc/issue.net

/usr/bin/ln -sf /dev/null /mnt/etc/udev/rules.d/80-net-setup-link.rules

/usr/bin/cat > /mnt/etc/profile.d/"${user}".sh << EOF
# default permissions
umask 027

# disable core dumps
ulimit -c 0

# set a 15 minute timeout policy for shells
readonly TMOUT=900
# readonly HISTFILE

EOF

/usr/bin/chmod 0640 /mnt/var/log/pacman.log
/usr/bin/chown root:wheel /mnt/var/log/pacman.log
/usr/bin/echo '/var/log/pacman.log {
	compress
	yearly
	create 0640 root wheel
	size 1M
	rotate 1
}
' >> /mnt/etc/logrotate.conf

# [ ! -d /mnt/etc/logrotate.d ] && /usr/bin/mkdir /mnt/etc/logrotate.d
# /usr/bin/cat > /mnt/etc/logrotate.d/pacman << EOF
# /var/log/pacman.log {
# 	compress
# 	yearly
# 	create 0640 root wheel
# 	size 1M
# 	rotate 1
# }
# EOF

/usr/bin/artix-chroot /mnt pacman -Ql gcc | grep '/usr/bin/.\+' | awk '{ print $2 }' | {
	while IFS= read -r file; do
		[ -f "/mnt${file}" ] && chmod o-rwx "/mnt${file}"
		[ -f "/mnt${file}" ] &&	chown root:wheel "/mnt${file}"
		[ -h "/mnt${file}" ] && chmod -h o-rwx "/mnt${file}"
		[ -h "/mnt${file}" ] &&	chown -h root:wheel "/mnt${file}"
	done
	chmod o-rwx "/mnt/usr/sbin/as"
	chown root:wheel "/mnt/usr/sbin/as"
}

/usr/bin/cat >> /mnt/etc/rkhunter.conf << EOF
SCRIPTWHITELIST=/usr/bin/egrep
SCRIPTWHITELIST=/usr/bin/fgrep
SCRIPTWHITELIST=/usr/bin/ldd
EOF

# Set hostname and hosts
echo "${hstname}" > /mnt/etc/hostname
/usr/bin/cat > /mnt/etc/hosts << EOF
# <localhost>
127.0.0.1		local
127.0.0.1		localhost
127.0.0.1		localhost.localdomain
255.255.255.255		broadcasthost
::1			localhost
::1			ip6-localhost ip6-loopback
fe00::0			ip6-localnet
fe00::1			ip6-allnodes
fe00::2			ip6-allrouters
fe00::3			ip6-allhosts
# </localhost>
EOF

/usr/bin/mkdir -p /mnt/var/cache/makepkg
/usr/bin/chmod 0750 /mnt/var/cache/makepkg
/usr/bin/sed -i 's/BUILDDIR=\/tmp\/makepkg/BUILDDIR=\/var\/cache\/makepkg/' /mnt/etc/makepkg.conf

echo "*	hard core	0" >> /mnt/etc/security/limits.conf
[ ! -d /mnt/etc/sysctl.d ] && /usr/bin/mkdir /mnt/etc/sysctl.d
/usr/bin/cat > /mnt/etc/sysctl.d/99-coredump.conf << EOF
fs.suid_dumpable=0
kernel.core_pattern=|/bin/false
EOF
/usr/bin/artix-chroot /mnt runuser -l root -c "sysctl -p /etc/sysctl.d/99-coredump.conf"

/usr/bin/chmod 0600 /mnt/etc/cron.deny
/usr/bin/chmod 0700 /mnt/etc/cron.d /mnt/etc/cron.daily /mnt/etc/cron.hourly /mnt/etc/cron.weekly /mnt/etc/cron.monthly

/usr/bin/sed -i 's/UMASK=0022/UMASK=0027/' /mnt/etc/conf.d/sysstat

/usr/bin/sed -i 's/active = no/active = yes/' /mnt/etc/audit/plugins.d/syslog.conf
[ -d /mnt/etc/audit/rules.d ] || /usr/bin/mkdir -p /mnt/etc/audit/rules.d
/usr/bin/cat >> /mnt/etc/audit/rules.d/${user}.rules << EOF
# attribution: https://github.com/Neo23x0/auditd
#			   https://linux-audit.com/tuning-auditd-high-performance-linux-auditing/

# Remove Existing Rules
-D

# Buffer Size
-b 8192

# Failure Mode (0: silent, 1: printk a failure message, 2: panic or halt system)
-f 1

# Ignore Errors
-i

# Self Auditing {{{
# Audit the Audit Logs
-w /var/log/audit/ -k auditlog

# Audit Configuration
-w /etc/audit/ -p wa -k auditconfig
-w /etc/libaudit.conf -p wa -k auditconfig
-w /etc/audisp/ -p wa -k auditconfig
# }}}

# Filters {{{
# Ignore Auditctl
-a always,exclude -F msgtype=CONFIG_CHANGE
-a always,exclude -F msgtype=SYSCALL -S 44
# Ignore SELinux AVC Records
-a always,exclude -F msgtype=AVC
# Ignore CWD Records
-a always,exclude -F msgtype=CWD
# Ignore End of Event Records
-a always,exclude -F msgtype=EOE
# Ignore Crypo Key
-a always,exclude -F msgtype=CRYPTO_KEY_USER
# VMware Tools
#-a exit,never -F arch=b32 -S fork -F success=0 -F path=/usr/lib/vmware-tools -F subj_type=initrc_t -F exit=-2
#-a exit,never -F arch=b64 -S fork -F success=0 -F path=/usr/lib/vmware-tools -F subj_type=initrc_t -F exit=-2
# High Volume Event Filter
-a exit,never -F arch=b32 -F dir=/dev/shm -k sharedmemaccess
-a exit,never -F arch=b64 -F dir=/dev/shm -k sharedmemaccess
-a exit,never -F arch=b32 -F dir=/var/lock/lvm -k locklvm
-a exit,never -F arch=b64 -F dir=/var/lock/lvm -k locklvm
# }}}

# Rules {{{
# Kernel Parameters
-w /etc/sysctl.conf -p wa -k sysctl
# Kernel Module Loading/Unloading
-a always,exit -F perm=x -F auid!=-1 -F path=/sbin/insmod -k modules
-a always,exit -F perm=x -F auid!=-1 -F path=/sbin/modprobe -k modules
-a always,exit -F perm=x -F auid!=-1 -F path=/sbin/rmmod -k modules
-a always,exit -F arch=b64 -S finit_module -S init_module -S delete_module -F auid!=-1 -k modules
-a always,exit -F arch=b32 -S finit_module -S init_module -S delete_module -F auid!=-1 -k modules
# Modprobe Configuration
-w /etc/modprobe.conf -p wa -k modprobe
# KExec Usage
-a always,exit -F arch=b64 -S kexec_load -k KEXEC
-a always,exit -F arch=b32 -S sys_kexec_load -k KEXEC
# Special Files
-a exit,always -F arch=b32 -S mknod -S mknodat -k specialfiles
-a exit,always -F arch=b64 -S mknod -S mknodat -k specialfiles
# Mount Operations (only attributable)
-a always,exit -F arch=b64 -S mount -S umount2 -F auid!=-1 -k mount
-a always,exit -F arch=b32 -S mount -S umount -S umount2 -F auid!=-1 -k mount
# Change Swap (only attributable)
-a always,exit -F arch=b64 -S swapon -S swapoff -F auid!=-1 -k swap
-a always,exit -F arch=b32 -S swapon -S swapoff -F auid!=-1 -k swap
# Time
-a exit,always -F arch=b32 -S adjtimex -S settimeofday -S clock_settime -k time
-a exit,always -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time
# Local Timezone
-w /etc/localtime -p wa -k localtime
# Cron Configuration & Jobs
-w /etc/cron.allow -p wa -k cron
-w /etc/cron.deny -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /etc/cron.daily/ -p wa -k cron
-w /etc/cron.hourly/ -p wa -k cron
-w /etc/cron.monthly/ -p wa -k cron
-w /etc/cron.weekly/ -p wa -k cron
-w /etc/crontab -p wa -k cron
-w /var/spool/cron/ -k cron
# User, Group & Passwd Databases
-w /etc/group -p wa -k etcgroup
-w /etc/passwd -p wa -k etcpasswd
-w /etc/gshadow -k etcgroup
-w /etc/shadow -k etcpasswd
# Sudo Configuration
-w /etc/sudoers -p wa -k actions
-w /etc/sudoers.d/ -p wa -k actions
# Passwd
-w /usr/bin/passwd -p x -k passwd_modification
# User/Group Modification
-w /usr/sbin/groupadd -p x -k group_modification
-w /usr/sbin/groupmod -p x -k group_modification
-w /usr/sbin/useradd -p x -k user_modification
-w /usr/sbin/usermod -p x -k user_modification
# Login Configuration
-w /etc/login.defs -p wa -k login
-w /etc/securetty -p wa -k login
-w /var/log/lastlog -p wa -k login
-w /var/log/tallylog -p wa -k login
# Hostname Changes
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k network_modifications
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network_modifications
# IPv4 Connections
-a always,exit -F arch=b64 -S connect -F a2=16 -F success=1 -F key=network_connect_4
-a always,exit -F arch=b32 -S connect -F a2=16 -F success=1 -F key=network_connect_4
# IPv6 Connections
-a always,exit -F arch=b64 -S connect -F a2=28 -F success=1 -F key=network_connect_6
-a always,exit -F arch=b32 -S connect -F a2=28 -F success=1 -F key=network_connect_6
# Network Configuration
-w /etc/hosts -p wa -k network_modifications
-w /etc/issue -p wa -k etcissue
-w /etc/issue.net -p wa -k etcissue
# Library Search Paths
-w /etc/ld.so.conf -p wa -k libpath
-w /etc/ld.so.conf.d/ -p wa -k libpath
# Pam Configuration
-w /etc/pam.d/ -p wa -k pam
-w /etc/security/limits.conf -p wa  -k pam
-w /etc/security/pam_env.conf -p wa -k pam
-w /etc/security/namespace.conf -p wa -k pam
-w /etc/security/namespace.init -p wa -k pam
# Postfix
-w /etc/aliases -p wa -k mail
-w /etc/postfix/ -p wa -k mail
# SSHD Configuration
-w /etc/ssh/ -p wa -k sshd
# Systemd
-w /bin/systemctl -p x -k systemd
-w /etc/systemd/ -p wa -k systemd
# SELinux MAC Events
-w /etc/selinux/ -p wa -k mac_policy
# Critical Access Failures
-a exit,always -F arch=b64 -S open -F dir=/etc -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/bin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/sbin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/usr/bin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/usr/sbin -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/var -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/home -F success=0 -k unauthedfileaccess
-a exit,always -F arch=b64 -S open -F dir=/srv -F success=0 -k unauthedfileaccess
# Privilege Escalation
-w /usr/sbin/su -p x -k priv_esc
-w /usr/sbin/sudo -p x -k priv_esc
-w /etc/sudoers -p rw -k priv_esc
# Power State
-w /usr/sbin/halt -p x -k power
-w /usr/sbin/poweroff -p x -k power
-w /usr/sbin/reboot -p x -k power
-w /usr/sbin/shutdown -p x -k power
# Session Information
-w /var/run/utmp -p wa -k session
-w /var/log/btmp -p wa -k session
-w /var/log/wtmp -p wa -k session
# Discretionary Access Control (DAC) Modifications
#-a always,exit -F arch=b32 -S chmod -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S chown -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S fchmod -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S fchown -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S fchownat -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S fsetxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S lremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S lsetxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S removexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b32 -S setxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S chmod  -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S chown -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S fchmod -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S fchmodat -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S fchown -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S fchownat -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S fremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S fsetxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S lchown -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S lremovexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S lsetxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S removexattr -F auid>=500 -F auid!=4294967295 -k perm_mod
#-a always,exit -F arch=b64 -S setxattr -F auid>=500 -F auid!=4294967295 -k perm_mod
# 32-bit API Exploitation
-a always,exit -F arch=b32 -S all -k 32bit_api
# Reconnaissance
-w /usr/sbin/whoami -p x -k recon
-w /etc/issue -p r -k recon
-w /etc/issue.net -p r -k recon
-w /etc/hostname -p r -k recon
# Suspicious Activity
-w /usr/sbin/wget -p x -k susp_activity
-w /usr/sbin/curl -p x -k susp_activity
-w /usr/sbin/base64 -p x -k susp_activity
-w /usr/sbin/ss -p x -k susp_activity
-w /usr/sbin/iptables -p x -k susp_activity
-w /usr/sbin/mtr -p x -k susp_activity
-w /usr/sbin/nft -p x -k susp_activity
-w /usr/sbin/tcpdump -p x -k susp_activity
-w /usr/sbin/traceroute -p x -k susp_activity
# Ptrace Injection
-a always,exit -F arch=b32 -S ptrace -k tracing
-a always,exit -F arch=b64 -S ptrace -k tracing
-a always,exit -F arch=b32 -S ptrace -F a0=0x4 -k code_injection
-a always,exit -F arch=b64 -S ptrace -F a0=0x4 -k code_injection
-a always,exit -F arch=b32 -S ptrace -F a0=0x5 -k data_injection
-a always,exit -F arch=b64 -S ptrace -F a0=0x5 -k data_injection
-a always,exit -F arch=b32 -S ptrace -F a0=0x6 -k register_injection
-a always,exit -F arch=b64 -S ptrace -F a0=0x6 -k register_injection
# Docker
-w /usr/bin/docker -p x -k docker
-w /usr/bin/docker-init -p x -k docker
-w /usr/bin/docker-proxy -p x -k docker
-w /usr/bin/dockerd -p x -k docker
-w /etc/docker/ -p wa -k docker
-w /var/lib/docker/ -p wa -k docker
# Unauthorized Creation
-a always,exit -F arch=b32 -S creat,link,mknod,mkdir,symlink,mknodat,linkat,symlinkat -F exit=-EACCES -k file_creation
-a always,exit -F arch=b64 -S mkdir,creat,link,symlink,mknod,mknodat,linkat,symlinkat -F exit=-EACCES -k file_creation
-a always,exit -F arch=b32 -S link,mkdir,symlink,mkdirat -F exit=-EPERM -k file_creation
-a always,exit -F arch=b64 -S mkdir,link,symlink,mkdirat -F exit=-EPERM -k file_creation
# Unauthorized Modification
-a always,exit -F arch=b32 -S rename -S renameat -S truncate -S chmod -S setxattr -S lsetxattr -S removexattr -S lremovexattr -F exit=-EACCES -k file_modification
-a always,exit -F arch=b64 -S rename -S renameat -S truncate -S chmod -S setxattr -S lsetxattr -S removexattr -S lremovexattr -F exit=-EACCES -k file_modification
-a always,exit -F arch=b32 -S rename -S renameat -S truncate -S chmod -S setxattr -S lsetxattr -S removexattr -S lremovexattr -F exit=-EPERM -k file_modification
-a always,exit -F arch=b64 -S rename -S renameat -S truncate -S chmod -S setxattr -S lsetxattr -S removexattr -S lremovexattr -F exit=-EPERM -k file_modification
# }}}

# Make Configuration Immutable
-e 2
EOF

# Configure /etc/nftables
/usr/bin/cat > /mnt/etc/nftables.conf << EOF
#!/usr/bin/nft -f
#
# IPv4/IPv6 Firewall

flush ruleset

table inet filter {

	set blacklist {
		type ipv4_addr
		flags constant, interval
		auto-merge
		elements = {
			1.2.3.4/32
		}
	}

	set blacklist6 {
		type ipv6_addr
		flags constant, interval
		auto-merge
		elements = {
			2a01:8fe0::/32
		}
	}

	chain input {
		type filter hook input priority filter; policy drop;

		# allow from loopback
		iifname lo accept comment "+loopback"

		# early drop of invalid connections
		ct state invalid drop comment "-invalid"

		# limit ping requests (10/second)
		ip6 nexthdr icmpv6 icmpv6 type echo-request limit rate 10/second accept comment "+ping6"
		ip protocol icmp icmp type echo-request limit rate 10/second accept comment "+ping"

		# limit specific icmp types (5/second)
		meta l4proto ipv6-icmp icmpv6 type { destination-unreachable, packet-too-big, time-exceeded, parameter-problem, mld-listener-query, mld-listener-report, mld-listener-reduction, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, ind-neighbor-solicit, ind-neighbor-advert, mld2-listener-report } limit rate 2/second accept comment "+icmp6"
		meta l4proto icmp icmp type { destination-unreachable, router-solicitation, router-advertisement, time-exceeded, parameter-problem } limit rate 2/second accept comment "+icmp"

		# allow connections established/related by/to this machine
		ct state { established, related } accept comment "+established"

		# drop loopback connections not coming from loopback
		iifname != lo ip6 daddr ::1/128 drop comment "-invalid_loopback6"
		iifname != lo ip daddr 127.0.0.1/8 drop comment "-invalid_loopback"

		# add blacklisted ips
		ip6 saddr @blacklist6 drop comment "blacklist6"
		ip saddr @blacklist drop comment "blacklist"

		# drop all fragments
		ip frag-off & 0x1fff != 0 counter drop comment "-fragments"

		# force SYN checks
		tcp flags & (fin|syn|rst|ack) != syn ct state new counter drop comment "+syn_checks"

		# drop XMAS packets
		tcp flags & (fin|syn|rst|psh|ack|urg) == fin|syn|rst|psh|ack|urg counter drop comment "-xmas"

		# drop NULL packets
		tcp flags & (fin|syn|rst|psh|ack|urg) == 0x0 counter drop comment "-null"

		# limit ssh (15/minute)
		tcp dport 4222 limit rate 15/minute accept comment "+sshd"

		# allow http and https traffic
		# tcp dport { http, https } accept comment "+httpd"

		# allow nfs traffic
		# meta l4proto { tcp, udp } th dport 2049 ip6 saddr { fd00::/8, fe80::/10 } accept comment "+nfs6"
		# meta l4proto { tcp, udp } th dport 2049 ip saddr { 10.0.0.0/24, 10.0.10.0/24 } accept comment "+nfs"

		# allow traffic from specific ip's
		# ip saddr { 1.2.3.4, 4.3.2.1 } tcp dport 1234 ct state { established, new } counter accept comment "+service"

		# allow a range of ports
		# ip dport { 1000-2000, 3000-4000 } accept comment "+range"

		# everything else (blackhole)
		reject with icmpx type port-unreachable comment "+blackhole"
	}

	# all forwarding traffic gets dropped (we are not a router)
	chain forward {
		type filter hook forward priority filter; policy drop;
	}

	# let all traffic outbound through the firewall
	chain output {
		type filter hook output priority filter; policy drop;
		ip6 nexthdr ipv6-icmp accept
		ct state invalid drop
		ct state { established, new, related } accept
	}

}
EOF

#
########################################################################################
#
# Network configuration
#
########################################################################################
#

/usr/bin/artix-chroot /mnt /usr/bin/wpa_passphrase ${ssid} ${wfpass} > /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
/usr/bin/sed -i "/#psk/d" /mnt/etc/wpa_supplicant/wpa_supplicant-wlan0.conf
[ ! -d /mnt/var/lib/connman ] && mkdir -p /mnt/var/lib/connman
/usr/bin/cat << EOF > /mnt/var/lib/connman/1PM4n.config
[service_${wfcon}]
Type = wifi
Name = ${ssid}
hidden=true
Passphrase = ${wfpass} 
EOF

#
########################################################################################
#
# Perform cleanups.
#
########################################################################################
#

swapoff /dev/$cvg/swap
umount -R /mnt
vgchange -a n
cryptsetup close cryptlvm

set +x
echo
echo '+########################+'
echo '| Istallation completed  |'
echo '+########################+'
