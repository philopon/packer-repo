#!/usr/bin/env bash

set -e

echo_progress() {
  echo "################################################################################"
  echo "#####" $@ "#####"
  echo "################################################################################"
}


# Install packages
echo_progress update and install packages
aptitude -y update
aptitude -y install python python-apt ca-certificates \
  build-essential module-assistant linux-headers-3.2.0-4-amd64
m-a prepare

## VirtualBox Guest Additions
echo_progress install guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
GUEST_ADDITIONS_PREFIX=/tmp/VBoxGuestAdditions_
cd /tmp
mount -o loop $GUEST_ADDITIONS_PREFIX$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run || true
ln -s /opt/VBoxGuestAdditions-$VBOX_VERSION/lib/VBoxGuestAdditions /usr/lib/VBoxGuestAdditions
umount /mnt
rm -rf $GUEST_ADDITIONS_PATH*.iso

## Install Vagrant 
echo_progress install vagrant key
date > /etc/vagrant_box_build_time
SSH_DIR=/home/vagrant/.ssh
VAGRANT_URL="http://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub"

mkdir -pm 700 $SSH_DIR

wget -O $SSH_DIR/authorized_keys $VAGRANT_URL
chmod 600 $SSH_DIR/authorized_keys 
chown -R vagrant:vagrant $SSH_DIR

## Cleanup
echo_progress cleanup
aptitude -y purge installation-report linux-headers-3.2.0-4-amd64

find /var/cache   -type f -exec rm -f {} \;
find /var/lib/apt -type f -exec rm -f {} \;
find /var/lib/apt -type d -exec touch -d '2000/1/1' {} \;

aptitude -y     clean
aptitude -y autoclean

find /var/log -type f -exec cp /dev/null {} \;

dd if=/dev/zero of=/whiteout bs=1k || true
rm /whiteout

dd if=/dev/zero of=/boot/whiteout bs=1k || true
rm /boot/whiteout

swap=`cat /proc/swaps        | awk -F ' ' '$2 == "partition" {print $1}'`
uuid=`blkid -o export $swap  | awk -F '=' '$1 == "UUID"      {print $2}'`

swapoff $swap
dd if=/dev/zero of=$swap bs=1k || true
mkswap -U "$uuid" $swap
swapon $swap

