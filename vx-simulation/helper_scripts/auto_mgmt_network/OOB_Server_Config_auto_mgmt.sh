#!/bin/bash
# Created by Topology-Converter v4.6.8
#    Template Revision: v4.6.8
#    https://github.com/cumulusnetworks/topology_converter
#    using topology data from: cl-piat.dot

echo "################################################"
echo "  Running Automatic Management Server Setup..."
echo "################################################"
echo -e "\n This script assumes an Ubuntu16.04 server."
echo " Detected vagrant user is: $username"


#######################
#       KNOBS
#######################

REPOSITORY="https://github.com/penguin02007"
REPONAME="cl-piat"

#Install Automation Tools
puppet=0
ansible=1
ansible_version=2.7.9

#######################

username=$(cat /tmp/normal_user)

install_puppet(){
    echo " ### Adding Puppet Repositories... ###"
    wget https://apt.puppetlabs.com/puppetlabs-release-pc1-xenial.deb
    dpkg -i puppetlabs-release-pc1-xenial.deb
    echo " ### Updating APT Repository... ###"
    apt-get update -y
    echo " ### Installing Puppet ###"
    apt-get install puppetserver -qy
    echo " ### Setting up Puppet ###"
    rm -rf /etc/puppetlabs/code/environments/production
    sed -i 's/-Xms2g/-Xms512m/g' /etc/default/puppetserver
    sed -i 's/-Xmx2g/-Xmx512m/g' /etc/default/puppetserver
    echo "*" > /etc/puppetlabs/puppet/autosign.conf
    sed -i 's/192.168.200.1/192.168.200.1 puppet /g'>> /etc/hosts
}

install_ansible(){
    echo " ### Installing Ansible... ###"
    apt-get install -qy ansible sshpass libssh-dev python-dev libssl-dev libffi-dev
    pip install pip --upgrade
    pip install setuptools --upgrade
    pip install ansible==$ansible_version --upgrade
}

## MOTD
echo " ### Overwriting MOTD ###"
cat <<EOT > /etc/motd.base64
ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIF8NChtbMDs0
MDszN20bWzZDG1szMW1fX19fX19fG1szN20gICAbWzE7MzJteBtbMG0gG1szMm14G1szN20gG1sz
Mm14G1szN20bWzI3Q3wgfA0KIBtbMzJtLl8bWzM3bSAgG1szMW08X19fX19fXxtbMTszM21+G1sw
bSAbWzMybXgbWzM3bSAbWzE7MzJtWBtbMG0gG1szMm14G1szN20gICBfX18gXyAgIF8gXyBfXyBf
X18gIF8gICBffCB8XyAgIF8gX19fDQobWzMybSgbWzM3bScgG1szMm1cG1szN20gIBtbMzJtLCcg
G1sxOzMzbXx8G1swOzMybSBgLBtbMzdtICAgIBtbMzJtIBtbMzdtICAgLyBfX3wgfCB8IHwgJ18g
YCBfIFx8IHwgfCB8IHwgfCB8IC8gX198DQogG1szMm1gLl86XhtbMzdtICAgG1sxOzMzbXx8G1sw
bSAgIBtbMzJtOj4bWzM3bRtbNUN8IChfX3wgfF98IHwgfCB8IHwgfCB8IHxffCB8IHwgfF98IFxf
XyBcDQobWzVDG1szMm1eVH5+fn5+flQbWzM3bScbWzdDXF9fX3xcX18sX3xffCB8X3wgfF98XF9f
LF98X3xcX18sX3xfX18vDQobWzVDG1szMm1+IhtbMzdtG1s1QxtbMzJtfiINChtbMzdtG1swMG0N
Cg0KIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMj
IyMjIyMjIyMjIyMjIyMjIyMjIyMjIw0KIw0KIyAgICAgICAgIE91dCBPZiBCYW5kIE1hbmFnZW1l
bnQgU2VydmVyIChvb2ItbWdtdC1zZXJ2ZXIpDQojDQojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMj
IyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjDQo=
EOT
base64 -d /etc/motd.base64 > /etc/motd
rm /etc/motd.base64
chmod 755 /etc/motd


echo " ### Overwriting /etc/network/interfaces ###"
cat <<EOT > /etc/network/interfaces
auto lo
iface lo inet loopback


auto vagrant
iface vagrant inet dhcp


auto eth1
iface eth1 inet static
    address 192.168.200.1/24
EOT

echo " ### ForceIpv4 on Apt"
sudo su -c "echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4"
echo " ### Overwriting DNS Server to 100.79.223.108 ###"
#Required because the installation of DNSmasq throws off DNS momentarily
grep 100.79.223.108 /etc/resolvconf/resolv.conf.d/head || echo "nameserver 100.79.223.108" >> /etc/resolvconf/resolv.conf.d/head

echo " ### Add http proxy ###"
grep http_proxy  ~/.bashrc || echo -e "export http_proxy=http://pkg.proxy.prod.jp.local:10080" >> ~/.bashrc
grep https_proxy ~/.bashrc || echo -e "export https_proxy=http://pkg.proxy.prod.jp.local:10080" >> ~/.bashrc
source ~/.bashrc

echo " ### Updating APT Repository... ###"
apt-get update -y

echo " ### Installing Packages... ###"
apt-get install -y htop isc-dhcp-server tree apache2 vlan git python-pip dnsmasq ifenslave apt-cacher-ng lldpd ntp
modprobe 8021q
#modprobe bonding
echo "8021q" >> /etc/modules

if [ $puppet -eq 1 ]; then
    echo " ### Installing Puppet ### "
    install_puppet
fi
if [ $ansible -eq 1 ]; then
    echo " ### Installing Ansible ### "
    install_ansible
fi

echo " ### Configure NTP... ###"
echo <<EOT >> /etc/ntp.conf
driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

server clock.rdu.cumulusnetworks.com

# By default, exchange time with everybody, but don't allow configuration.
restrict -4 default kod notrap nomodify nopeer noquery
restrict -6 default kod notrap nomodify nopeer noquery

# Local users may interrogate the ntp server more closely.
restrict 127.0.0.1
restrict ::1
EOT

echo " ### Creating cumulus user ###"
useradd -m cumulus

echo " ### Setting Up DHCP ###"
mv /home/$username/dhcpd.conf /etc/dhcp/dhcpd.conf
mv /home/$username/dhcpd.hosts /etc/dhcp/dhcpd.hosts
chmod 755 -R /etc/dhcp/*
systemctl restart isc-dhcp-server

echo " ### Setting up ZTP ###"
mv /home/$username/ztp_oob.sh /var/www/html/ztp_oob.sh

echo " ### Setting Up Hostfile ###"
mv /home/$username/hosts /etc/hosts

echo " ### Moving Ansible Hostfile into place ###"
mkdir -p /etc/ansible
mv /home/$username/ansible_hostfile /etc/ansible/hosts

echo " ###Creating SSH keys for cumulus user ###"
mkdir /home/cumulus/.ssh
/usr/bin/ssh-keygen -b 2048 -t rsa -f /home/cumulus/.ssh/id_rsa -q -N ""
cp /home/cumulus/.ssh/id_rsa.pub /home/cumulus/.ssh/authorized_keys

chown -R cumulus:cumulus /home/cumulus/
chown -R cumulus:cumulus /home/cumulus/.ssh
chmod 700 /home/cumulus/.ssh/
chmod 600 /home/cumulus/.ssh/*
chown cumulus:cumulus /home/cumulus/.ssh/*

echo "<html><h1>You've come to the OOB-MGMT-Server.</h1></html>" > /var/www/html/index.html

echo "Copying Key into /var/www/html..."
cp /home/cumulus/.ssh/id_rsa.pub /var/www/html/authorized_keys
chmod 777 -R /var/www/html/*

echo " ###Making cumulus passwordless sudo ###"
echo "cumulus ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/10_cumulus

echo " ###Auto login cumulus user ###"
echo "sudo su - cumulus" >> /home/vagrant/.bash_profile
echo "exit" >> /home/vagrant/.bash_profile

echo ' ### Setting UP NAT and Routing on MGMT server... ### '
echo -e '#!/bin/bash \n/sbin/iptables -t nat -A POSTROUTING -o vagrant -j MASQUERADE' > /etc/rc.local
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/98-ipforward.conf


echo " ### Creating turnup.sh script ###"
    cat <<EOT >> /home/cumulus/turnup.sh
EOT

if [ $puppet -eq 1 ]; then
    cat <<EOT >> /home/cumulus/turnup.sh
sudo rm -rf /etc/puppetlabs/code/environments/production
sudo ln -s  /home/cumulus/$REPONAME/puppet/ /etc/puppetlabs/code/environments/production
sudo /opt/puppetlabs/bin/puppet module install puppetlabs-stdlib
#sudo bash -c 'echo "certname = 192.168.200.1" >> /etc/puppetlabs/puppet/puppet.conf'
echo " ### Starting PUPPET Master ###"
echo "     (this may take a while 30 secs or so...)"
sudo systemctl restart puppetserver.service
EOT
fi
if [ $ansible -eq 1 ]; then
    cat <<EOT >> /home/cumulus/turnup.sh
#Add any ansible specific steps here
EOT
fi

chmod +x /home/cumulus/turnup.sh

echo " ### creating .gitconfig for cumulus user"
cat <<EOT >> /home/cumulus/.gitconfig
[push]
  default = matching
[color]
    ui = true
[credential]
    helper = cache --timeout=3600
[core]
    editor = vim
EOT

sudo su - cumulus -c '\
git config --global http.proxy http://pkg.proxy.prod.jp.local:10080
git clone https://github.com/CumulusNetworks/cl-piat.git;
ansible-playbook /home/cumulus/cl-piat/vx-simulation/helper_scripts/install-runner-live.yaml;\
'




echo "############################################"
echo "      DONE!"
echo "############################################"
