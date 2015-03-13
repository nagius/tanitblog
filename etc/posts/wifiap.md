---
title: Wifi access point on a Raspberry Pi
date: 20140916
tags:
 - Network
 - Linux
---

My cable modem from UPC, a Technicolor model TC7200U, is really REALLY shitty. I think there is a bug in it, a kind of memory overflow, as I need to reboot it each day in order to get network...
Even accessing to the web admin interface make the modem reboot half the time.

So I decided to enable the bridge mode on this device and start using my Raspberry Pi as an access point and router for my home network.
My Pi was provided with a WiPi dongle, an USB wifi adapter powered by a RT5370 Ralink chipset, which support AP mode, 802.11bg and WPA2.

# Hardware configuration

First step, enable the bridge mode.

That's not so easy, because the configuration option to change the routing mode, as shown in the documentation, is missing, probably disabled by the ISP.

Luckily, I found a hack on this blog (thanks [Ivucica](http://blog.vucica.net/2014/01/few-notes-on-upc-irelands-technicolor-tc7200.html)) to enable bridge mode on this crappy device.
You need to follow these steps :

 - Power off the device
 - Unplug the coax cable
 - Switch it on
 - Run this command from a computer connected to the wired port : 

`snmpset -v2c -c public 192.168.0.1 1.3.6.1.4.1.4413.2.2.2.1.7.1.1.0 i 1`

 - Wait few seconds and power off the modem again.
 - Plug the coax cable and switch it on.  
  
  
Be careful, once switched to bridge mode I wasn't able to reach the admin interface (on 192.168.100.1), so make sure to disable the wifi before !
In my case, if the wifi is enable on the router, the wired ports don't work anymore...

To turn it back to normal mode, the only way I found is the factory reset.

As a strange side effect, when I had connected multiple devices by Wifi, I got multiple public IP... thanks UPC Ireland !

So, now eth0 is wired to the bridged modem, and wlan0 is my local network.

# Setting up the network

We configure eth0 as a DHCP client to get a public IP from the ISP, and wlan0 will be the gateway for the LAN, so we set a static ip.

```
/etc/network/interfaces:

auto eth0
iface eth0 inet dhcp

auto wlan0
iface wlan0 inet static
		address 192.168.1.1
		netmask 255.255.255.0
```

We also need a DHCP server and a DNS relay. Let's use DNSmasq for this tiny task.
Here are the main configuration options to set up:

```
/etc/dnsmasq.conf:

interface=wlan0
domain=home.lan
dhcp-range=192.168.1.10,192.168.1.90,24h
```

# Setting up the wifi 

The access point and WPA2 authentication are done by `hostapd`:

```
/etc/hostapd/hostapd.conf:

interface=wlan0
driver=nl80211

# (IN == INDIA, UK == United Kingdom, US == United Stats and so on ) 
country_code=FR

# Wireless network name 
ssid=MySSID

# The RaspberryPi is slow, no need of 802.11n, let's go with g only
hw_mode=g
channel=1

# Set WPA2-PSK 
wpa=2
wpa_passphrase=MyAwsomePassword
wpa_key_mgmt=WPA-PSK
auth_algs=1

# Set cipher suites (encryption algorithms)
# TKIP = Temporal Key Integrity Protocol
# CCMP = AES in Counter mode with CBC-MAC
wpa_pairwise=CCMP

# Accept all MAC address 
macaddr_acl=0
```

# Connecting to the Wild

In order to get access to internet, we need to enable routing and add some firewall rules. 

At the end of `/etc/sysctl.conf`:

```
# Enable routing
net.ipv4.ip_forward = 1
```

Run `sysctl -p` to load the change without rebooting.

And, in your iptable configuration file (load it with `iptable-restore`) :

```
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
# Enable NAT for wireless network
-A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
COMMIT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -s 192.168.1.0/24 -i wlan0 -j ACCEPT
-A INPUT -i eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
# Enable DHCP request from wifi
-A INPUT -i wlan0 -p udp -m udp --sport 67:68 --dport 67:68 -j ACCEPT
# Enable SSH access from Internet with anti brute force limit
-A INPUT -i eth0 -p tcp -m tcp --dport 22 -m state --state NEW -m limit --limit 2/min --limit-burst 3 -j ACCEPT
# Enable routing
-A FORWARD -s 192.168.1.0/24 -i wlan0 -j ACCEPT
-A FORWARD -d 192.168.1.0/24 -i eth0 -j ACCEPT
COMMIT
```

That's all ! Start all services (`dnsmasq`, `hostapd` and `iptables`), and you're ready to connect.

# Feedback

After a few days running this setup, everything is working fine and is stable. No Rasberry Pi freeze, no Wifi drop.

But I can download at a maximum of 1.5 MB/s (which is half of my ISP bandwidth), with a CPU usage raising up to 70-80% and a lot of softirq.
Using Wifi over USB seems to add a huge overhead. As soon as I'm doing something else on this Pi, the CPU becomes a bottleneck...

Maybe I will give a try to the Banana Pi !


