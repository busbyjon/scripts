#!/bin/bash -x
# Get any updates / install and remove pacakges
apt-get update
apt-get -y purge wolfram-engine # PIXEL only
/bin/bash -c 'APT_LISTCHANGES_FRONTEND=none apt-get -y dist-upgrade'
apt-get -y install bridge-utils wiringpi screen minicom

# Disable APIPA addresses on ethpiX and eth0
echo -e "# ClusterHAT\ndenyinterfaces eth0 ethpi1 ethpi2 ethpi3 ethpi4" >> /etc/dhcpcd.conf


# Enable uart (needed for Pi Zero W)
lua - enable_uart 1 /boot/config.txt <<EOF > /boot/config.txt.bak
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
  if line:match("^#?%s*"..key.."=.*$") then
    line=key.."="..value
    made_change=true
  end
  print(line)
end

if not made_change then
  print(key.."="..value)
end
EOF
mv /boot/config.txt.bak /boot/config.txt

# Setup a getty on the gadget serial port
ln -fs /lib/systemd/system/getty@.service \
/etc/systemd/system/getty.target.wants/getty@ttyGS0.service

# Change the hostname to "controller"
sed -i "s#^127.0.1.1.*#127.0.1.1\tcontroller#g" /etc/hosts
echo "controller" > /etc/hostname

# Get the cluster HAT software/config files
wget -O - --quiet http://dist.8086.net/clusterhat/clusterhat-files-latest.tgz | tar -zxvC /

# Copy network config files
cp -f /usr/share/clusterhat/interfaces.c /etc/network/interfaces

# Disable the auto filesystem resize
#sed -i 's/ quiet init=.*$//' /boot/cmdline.txt

# Setup config.txt file
C=`grep -c "dtoverlay=dwc2" /boot/config.txt`
if [ "x$C" = "x0" ];then
 echo -e "# Load overlay to allow USB Gadget devices\n#dtoverlay=dwc2" >> /boot/config.txt
fi

apt-get -y autoremove --purge
apt-get clean

