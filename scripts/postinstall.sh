apt-get -y update
apt-get -y upgrade
apt-get -y install linux-headers-$(uname -r) build-essential nfs-common
sudo apt-get -y -q install curl wget

if test -f .vbox_version ; then
  echo "installing VirtualBox Guest Additions..."
  apt-get -y install dkms
  mount -o loop /home/vagrant/VBoxGuestAdditions.iso /mnt
  sh /mnt/VBoxLinuxAdditions.run
  umount /mnt
  rm VBoxGuestAdditions.iso
  echo "installation completed..."
else
  echo "installing VMWare Tools..."
  mount -o loop /home/vagrant/VMWareTools.iso /mnt
  tar xzvf /mnt/VMwareTools-*.tar.gz -C /tmp/
  /tmp/vmware-tools-distrib/vmware-install.pl -d
  umount /mnt
  rm VMWareTools.iso
  /usr/bin/vmware-config-tools.pl -d
  echo "installation completed..."
fi

echo "setup sudo to allow no-password sudo for 'ubuntu'"
groupadd -r vagrant
usermod -a -G vagrant
cp /etc/sudoers /etc/sudoers.orig
sed -i -e '/Defaults\s\+env_reset/a Defaults\texempt_group=vagrant' /etc/sudoers
sed -i -e '/Defaults\s\+env_reset/a Defaults\tenv_keep+=SSH_AUTH_SOCK' /etc/sudoers
sed -i -e '/Defaults\s\+env_reset/a Defaults\tenv_keep+=PATH' /etc/sudoers
sed -i -e 's/%ubuntu ALL=(ALL) ALL/%ubuntu ALL=NOPASSWD:ALL/g' /etc/sudoers

# apt-get install various things necessary (e.g., NFS client, Ruby)
# and remove optional things to trim down the machine.
apt-get -y install nfs-common openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison pkg-config libgdbm-dev libffi-dev ruby rubygems
apt-get clean

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Install Puppet
wget http://apt.puppetlabs.com/puppetlabs-release-precise.deb
dpkg -i puppetlabs-release-precise.deb
apt-get update
apt-get -y install puppet-common=3.3.0-1puppetlabs1
apt-get -y install puppet=3.3.0-1puppetlabs1

# Remove items used for building, since they aren't needed anymore
apt-get -y remove linux-headers-$(uname -r)
apt-get -y autoremove

# Start Puppet
service puppet start

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp/*

# Make sure Udev doesn't block our network
# http://6.ptmc.org/?p=164
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces

# Zero out the free space to save space in the final image:
echo "Zeroing device to make space..."
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

sed -i 's/set timeout.*$/set timeout=10/' /etc/grub.d/00_header
sudo update-grub

exit