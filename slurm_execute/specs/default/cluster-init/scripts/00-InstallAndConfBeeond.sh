#!/bin/bash

# Let's start by checking packages, install missing :
if [[ $(rpm -qa | grep epel-release) ]]
then
        echo "Epel release already installed, next.\n"
else
        yum install -y epel-release
fi

if [[ $(rpm -qa | grep htop) ]]
then
        echo "htop already installed, next.\n"
else
        yum install -y htop
fi

MOUNT_ROOT=/mnt/resource
mkdir $MOUNT_ROOT

VMSIZE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2018-10-01" | jq -r '.compute.vmSize')
if [[ $VMSIZE =~ "rs_v3" ]]; then
        # Configure mdraid on NVMe SSD's on HBv3 :
        if [[ -e /dev/nvme0n1 ]];
        then # Setup RAID0 on HBv3 NVMe disks:
                mdadm --create --verbose /dev/md0 --level=stripe --raid-devices=2 /dev/nvme0n1 /dev/nvme1n1
                mkfs.ext4 /dev/md0
                umount $MOUNT_ROOT
                mount /dev/md0 $MOUNT_ROOT
                chmod 777 -R $MOUNT_ROOT
        fi
else
        if [[ -e /dev/nvme0n1 ]]; then
                mkfs.ext4 /dev/nvme0n1
                umount $MOUNT_ROOT
                mount /dev/nvme0n1 $MOUNT_ROOT
                chmod 777 -R $MOUNT_ROOT
        else
                echo "no NVMe found, best of luck"
        fi
fi

#Install Beeond packages :
rpm --import https://www.beegfs.io/release/beegfs_7.2.6/gpg/GPG-KEY-beegfs
wget -O /etc/yum.repos.d/beegfs_rhel8.repo https://www.beegfs.io/release/beegfs_7.2.6/dists/beegfs-rhel8.repo
yum install -y beegfs-client
yum install -y psmisc libbeegfs-ib beeond pdsh
sed -i 's/^buildArgs=-j8/buildArgs=-j8 OFED_INCLUDE_PATH=\/usr\/src\/ofa_kernel\/default\/include/g' /etc/beegfs/beegfs-client-autobuild.conf
sed -i 's/^#include <asm\/kmap_types.h>//g' /opt/beegfs/src/client/client_module_7/source/os/OsCompat.h
/etc/init.d/beegfs-client rebuild || exit 1
# Local folder used on every compute node to start beeond
mkdir $MOUNT_ROOT/beeond
chmod 777 $MOUNT_ROOT/beeond
# Beeond mount point
mkdir /beeond
chmod 777 /beeond
## This is to set rights to your nfsoblob storage space, my mount point is hpcpersistent :
#chmod 777 /hpcpersistent

# trick, we need key pairs as we run as root the prolog & beeond needs to start as root.
## HEre be careful with AzureUser
/usr/bin/cp -fr /shared/home/azureuser/.ssh /root/
sed -i 's/^PermitRootLogin no/PermitRootLogin without-password/g' /etc/ssh/sshd_config
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/g' /etc/ssh/sshd_config
rm -f /root/.ssh/known_hosts
systemctl restart sshd

# Disabling selinux
setenforce 0
sed -i s/SELINUX=enforcing/SELINUX=DISABLED/i /etc/selinux/config
