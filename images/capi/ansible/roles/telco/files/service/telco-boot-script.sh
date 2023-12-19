#!/bin/bash
#
# Copyright (C) 2021 VMware, Inc. All rights reserved.
#
#set -x
#set -e

logfile="/var/log/telco-boot.log"
echo "Start to execute telco-boot service script" >> $logfile


install_iavf() {
    echo "============================" >> $logfile
    echo "Start to execute install_iavf" >> $logfile

    iavfDir="/opt/vmware/iavf"
    iavFile=$iavfDir/$(uname -r)-iavf.ko.xz
    if [ ! -f "$iavFile" ]; then
        echo "$iavFile does not exist, exit install_iavf" >> $logfile
        return 0
    fi

    if modinfo iavf > /dev/null 2>&1; then
        echo $(modinfo iavf) >> $logfile
        echo "iavf has been loaded, exit install_iavf" >> $logfile
        return 0
    fi

    rmmod iavf
    cp $iavfDir/iavf.conf /etc/modprobe.d/iavf.conf

    cp $iavFile /lib/modules/$(uname -r)/extra/iavf.ko.xz
    chmod 644 /lib/modules/$(uname -r)/extra/iavf.ko.xz
    depmod -e -F /boot/System.map-$(uname -r)  -a $(uname -r)
    modprobe iavf
    dracut --force
    if [ ! -f /boot/initrd.img-$(uname -r)-old ]; then
        mv /boot/initrd.img-$(uname -r) /boot/initrd.img-$(uname -r)-old
    fi
    mv /boot/initramfs-$(uname -r).img /boot/initrd.img-$(uname -r)

    echo "iavf has been loaded" >> $logfile
    echo $(modinfo iavf) >> $logfile

    echo "End to execute install_iavf" >> $logfile
}

# 20210109 currently only install i40e(2.12.6) driver for rt-kernel-4.19.132
install_i40e() {
    echo "============================" >> $logfile
    echo "Start to execute install_i40e" >> $logfile

    i40eDir="/opt/vmware/i40e"
    i40eFile=$i40eDir/$(uname -r)-i40e.ko.xz
    if [ ! -f "$i40eFile" ]; then
        echo "$i40eFile does not exist, exit install_i40e" >> $logfile
        return 0
    fi

    i40eVer=$(modinfo i40e | grep version -w | awk {'print $2'})
    if [[ "$i40eVer" == "2.12.6" ]]; then
        echo "current i40e version is already 2.12.6, exit install_i40e" >> $logfile
        return 0
    fi

    rmmod i40e
    mkdir old-module
    if [ ! -f old-module/i40e.ko.xz ]; then
        mv /lib/modules/$(uname -r)/extra/i40e.ko.xz old-module/
    fi
    cp $i40eFile /lib/modules/$(uname -r)/extra/i40e.ko.xz
    chmod 644 /lib/modules/$(uname -r)/extra/i40e.ko.xz
    depmod -e -F /boot/System.map-$(uname -r)  -a $(uname -r)
    modprobe i40e
    dracut --force
    if [ ! -f /boot/initrd.img-$(uname -r)-old ]; then
        mv /boot/initrd.img-$(uname -r) /boot/initrd.img-$(uname -r)-old
    fi
    mv /boot/initramfs-$(uname -r).img /boot/initrd.img-$(uname -r)

    echo "End to execute install_i40e successfully" >> $logfile
}

install_ice() {
    echo "============================" >> $logfile
    echo "Start to execute install_ice" >> $logfile

    iceDir="/opt/vmware/ice"
    iceFile=$iceDir/$(uname -r)-ice.ko.xz
    if [ ! -f "$iceFile" ]; then
        echo "$iceFile does not exist, exit install_ice" >> $logfile
        return 0
    fi

    iceVer=$(modinfo ice | grep version -w | awk {'print $2'})
    if [[ "$iceVer" == "1.3.2" ]]; then
        echo "current ice version is already 1.3.2, exit install_ice" >> $logfile
        return 0
    fi

    rmmod ice
    mkdir old-module
    if [ ! -f old-module/ice.ko.xz ]; then
        mv /lib/modules/$(uname -r)/extra/ice.ko.xz old-module/
    fi

    cp $iceFile /lib/modules/$(uname -r)/extra/ice.ko.xz
    chmod 644 /lib/modules/$(uname -r)/extra/ice.ko.xz

    mkdir -p /lib/firmware/updates/intel/ice/
    cp -r $iceDir/ddp/$(uname -r)-ice.pkg /lib/firmware/updates/intel/ice/

    depmod -e -F /boot/System.map-$(uname -r)  -a $(uname -r)
    modprobe ice
    dracut --force
    if [ ! -f /boot/initrd.img-$(uname -r)-old ]; then
        mv /boot/initrd.img-$(uname -r) /boot/initrd.img-$(uname -r)-old
    fi
    mv /boot/initramfs-$(uname -r).img /boot/initrd.img-$(uname -r)

    echo "End to execute install_ice successfully" >> $logfile
}

# 20210516 except eth0, other eth interface's mtu is same with config in 99-dhcp-en.link and 99-dhcp-en.network
set_99_dhcp_en_network() {
    sed -i "s/Name=eth0/Name=e\*/g" /etc/systemd/network/99-dhcp-en.network
}

#default ova template does not set mtu
#set_99_dhcp_en_network

remove_builder_user(){
    echo "============================" >> $logfile
    echo "Try to remove the builder account" >> $logfile

    user="builder"
    id $user
    if [ $? -ne 0 ]; then
        echo "$user does not exist, exit remove_builder_user" >> $logfile
        return 0
    else
        echo "$user exists, execute remove_builder_user" >> $logfile
        userdel -r -f builder
        return 0
    fi
}

# Begin for kernel 132
install_i40e
install_iavf
install_ice
# End for kernel 132

# Remove "builder" account when the node first boot

remove_builder_user

