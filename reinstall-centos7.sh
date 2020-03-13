#!/bin/bash
if command -v wget >/dev/null 2>&1;then
	clear
	else echo "ERROR:  please install wget"
fi
############################################
dl(){
	local image='https://github.com/wuntel/anybbr/raw/master/centos-7.7-x86_64-docker.tar.xz'
		local busybox='https://busybox.net/downloads/binaries/1.31.0-defconfig-multiarch-musl/busybox-x86_64'
			[ -d /tmpos ] || mkdir /tmpos
				wget -qO /tmpos/centos7.tar.xz ${image} && wget -qO /tmpos/busybox ${busybox} && chmod 777 /tmpos/busybox
}
############################################
backup-data(){
	cp /etc/resolv.conf /etc/fstab /tmpos
}
############################################
del-root(){
	if command -v chattr >/dev/null 2>&1; then
		find / -type f \( ! -path '/dev/*' -and ! -path '/proc/*' -and ! -path '/sys/*' -and ! -path '/selinux/*' -and ! -path "/tmpos/*" \) \
			-exec chattr -i {} + 2>/dev/null || true
	fi
		find / \( ! -path '/dev/*' -and ! -path '/proc/*' -and ! -path '/sys/*' -and ! -path '/selinux/*' -and ! -path "/tmpos/*" \) -delete 2>/dev/null || true
}
############################################
un-xz(){
	local tar='/tmpos/busybox tar'
	local xzcat='/tmpos/busybox xzcat'
		${xzcat} /tmpos/centos7.tar.xz | ${tar} -x -C /
}
############################################
restore-data(){
	mv /tmpos/resolv.conf /tmpos/fstab /etc
	##chpasswd
		echo "root:cnddy10" | chpasswd
}
############################################
installer-pak(){
	yum -y install grub2 dhclient openssh-server kernel dracut-network || true
		##enable sshd
			sed -i '/^#PermitRootLogin\s/s/.*/&\nPermitRootLogin yes/' /etc/ssh/sshd_config && systemctl enable sshd
}
############################################
create-kernel-image(){
	dracut -fNm "bash base kernel-modules rootfs-block network shutdown" --kver "3.10.0-1062.12.1.el7.x86_64" 2>/dev/null
}
############################################
config-network(){
	touch /etc/sysconfig/network
		route=$(ip route get 1.1.1.1 | awk '{print $3}')
		ip=$(ip -o -4 a|grep -Ev  '\s(docker|lo)'|awk '{print $4}'|cut -d/ -f1)
			cat >/etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
IPADDR=$ip
PREFIX=8
GATEWAY=$route
DNS1=8.8.8.8
DNS2=1.1.1.1
EOF
}
###########################################
config-grub(){
	local dev=$(ls /sys/block)
		grub2-install ${dev}
			grub2-mkconfig -o /boot/grub2/grub.cfg
}
###########################################
echo "

Install centos7 successfully  ;     default root password:  cnddy10

please run sync;reboot -f
"
