  #!/bin/bash

echo "#################################"
echo "  Running Extra_Server_Config.sh"
echo "#################################"
if [ "$HOSTNAME" != netq-ts ]; then
  sudo su
  echo " ### ForceIpv4 on Apt"
  echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
  useradd cumulus -m -s /bin/bash
  echo "cumulus:CumulusLinux!" | chpasswd
  usermod -aG sudo cumulus
  echo "cumulus ALL=(ALL) NOPASSWD:ALL" | tee --append /etc/sudoers.d/20_cumulus

  #Test for Debian-Based Host
  which apt &> /dev/null
  if [ "$?" == "0" ]; then
      #These lines will be used when booting on a debian-based box
      echo -e "note: ubuntu device detected"
      echo -e "Setting Proxy"
      export http_proxy=http://pkg.proxy.prod.jp.local:10080
      export https_proxy=http://pkg.proxy.prod.jp.local:10080
      #Install LLDP
      apt-get update -qy && apt-get install lldpd -qy
      apt-get install python -qy
      echo "configure lldp portidsubtype ifname" > /etc/lldpd.d/port_info.conf

      #Replace existing network interfaces file
      echo -e "auto lo" > /etc/network/interfaces
      echo -e "iface lo inet loopback\n\n" >> /etc/network/interfaces
      echo -e  "source /etc/network/interfaces.d/*.cfg\n" >> /etc/network/interfaces

      #Add vagrant interface
      echo -e "\n\nauto vagrant" > /etc/network/interfaces.d/vagrant.cfg
      echo -e "iface vagrant inet dhcp\n\n" >> /etc/network/interfaces.d/vagrant.cfg

      echo -e "\n\nauto eth0" > /etc/network/interfaces.d/eth0.cfg
      echo -e "iface eth0 inet dhcp" >> /etc/network/interfaces.d/eth0.cfg
      #Setup SSH key authentication for Ansible
      echo -e "post-up mkdir -p /home/cumulus/.ssh" >> /etc/network/interfaces.d/eth0.cfg
      echo -e "post-up wget -O /home/cumulus/.ssh/authorized_keys http://192.168.200.1/authorized_keys" >> /etc/network/interfaces.d/eth0.cfg
      echo -e "post-up chown -R cumulus:cumulus /home/cumulus/.ssh" >> /etc/network/interfaces.d/eth0.cfg
      echo -e "dns-nameservers 100.79.223.108" >> /etc/network/interfaces.d/eth0.cfg
      echo "retry 1;" >> /etc/dhcp/dhclient.conf
      
  fi

  #Test for Fedora-Based Host
  which yum &> /dev/null
  if [ "$?" == "0" ]; then
      echo -e "note: fedora-based device detected"
      /usr/bin/dnf install python -y
      echo -e "DEVICE=vagrant\nBOOTPROTO=dhcp\nONBOOT=yes" > /etc/sysconfig/network-scripts/ifcfg-vagrant
      echo -e "DEVICE=eth0\nBOOTPROTO=dhcp\nONBOOT=yes" > /etc/sysconfig/network-scripts/ifcfg-eth0

  fi

fi
echo "#################################"
echo "   Finished"
echo "#################################"
