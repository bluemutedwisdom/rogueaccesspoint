# Rogue access point

Rogue access point is a small script that create an access point that listen to all SSID's
and will provide an internet connection to the SSID. When this rogue access point is up the
script will spawn 3 terminals.

    - Terminal 1: This is an airbase-ng terminal for the rogue access point
    - Terminal 2: This is a sslstrip terminal for stripping ssl (https -> http)
    - Terminal 3: This is an ettercap terminal for dumping network traffic

After sslstripping you will see username and password information in clear text in the
ettercap terminal.

## Requirements

In order to run this script you need to have the following packages installed in you linux box

    - airmon-ng
    - airbase-ng
    - dhcpd / isc-dhcp-server
    - sslstrip
    - ettercap

These packages are default installed in [Kali Linux](https://www.kali.org/).

## Legal

This script is for educational purposes and penetration testing purposes only. The creator of
this script is in no way responsible for the action of the user. And can not held accountable for
any damage to this or an other's system.
