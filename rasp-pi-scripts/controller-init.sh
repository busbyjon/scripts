#!/bin/bash -x
# Get any updates / install and remove pacakges
apt-get update
apt-get -y upgrade
apt-get -y purge wolfram-engine # PIXEL only
/bin/bash -c 'APT_LISTCHANGES_FRONTEND=none apt-get -y dist-upgrade'
apt-get -y install bridge-utils wiringpi screen minicom

# Disable APIPA addresses on ethpiX and eth0
echo -e "# ClusterHAT\ndenyinterfaces eth0 ethpi1 ethpi2 ethpi3 ethpi4" >> /etc/dhcpcd.conf

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

echo "post-up ip link set br0 address b8:27:eb:91:ba:5c" >> /etc/network/interfaces


cp configuration.yaml /home/homeassistant/.homeassistant/


# Install the kiosk mode stuff
apt-get update
apt-get -y install raspberrypi-ui-mods x11-xserver-utils unclutter chromium-browser

sed -e '/@xscreensaver -no-splash/s/^/#/g' -i /etc/xdg/lxsession/LXDE-pi/autostart
echo -e '@xset s off\n@xset -dpms\n@xset s noblank\n@chromium-browser --noerrdialogs --kiosk http://192.168.0.201:3000 --incognito' >> /etc/xdg/lxsession/LXDE-pi/autostart

# Rotate the display
echo "lcd_rotate=2" >> /boot/config.txt

sed -i -e '$i \clusterhat on all\n' /etc/rc.local

#datadog

apt-get install sysstat

DD_API_KEY=API KEY sh -c "$(curl -L https://raw.githubusercontent.com/DataDog/dd-agent/master/packaging/datadog-agent/source/setup_agent.sh)"
sed -i -e '$i \nohup sh /home/pi/.datadog-agent/bin/agent &\n' /etc/rc.local
