#!/bin/bash

echo "#################################"
echo "   Running OOB_Switch_Config.sh"
echo "#################################"
sudo su

# Config for OOB Switch
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto vagrant
iface vagrant inet dhcp

#auto eth0
#iface eth0 inet dhcp

source /etc/network/interfaces.d/*
EOT
echo " ###Making cumulus passwordless sudo ###"
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus

echo " ###Auto login cumulus user ###"
echo "sudo su - cumulus" >> /home/vagrant/.bash_profile
echo "exit" >> /home/vagrant/.bash_profile
#/usr/share/doc/ifupdown2/examples/generate_interfaces.py -b | grep -v "#" >> /etc/network/interfaces.d/bridge

#sed -i 's/vagrant//g' /etc/network/interfaces.d/bridge
#sed -i 's/eth0//g' /etc/network/interfaces.d/bridge
#sed -i 's/iface bridge-untagged/iface bridge-untagged inet dhcp/' /etc/network/interfaces.d/bridge

cp /home/vagrant/bridge-untagged /etc/network/interfaces.d/bridge-untagged



echo "#################################"
echo "   Finished "
echo "#################################"

