#!/bin/bash

echo "#################################"
echo "  Running Extra_Switch_Config.sh"
echo "#################################"
sudo su
echo -e "export http_proxy=http://pkg.proxy.prod.jp.local:10080" >> ~/.bashrc
echo -e "export https_proxy=http://pkg.proxy.prod.jp.local:10080" >> ~/.bashrc

echo "retry 1;" >> /etc/dhcp/dhclient.conf

cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback

auto vagrant
iface vagrant inet dhcp

auto eth0
iface eth0 inet dhcp

EOT
echo "Force DHCP renew on swp1"
dhclient swp1
#add line to support bonding inside virtualbox VMs
#sed -i '/.*iface swp.*/a\    #required for traffic to flow on Bonds in Vbox VMs\n    post-up ip link set $IFACE promisc on' /etc/network/interfaces

echo "#################################"
echo "   Finished"
echo "#################################"
