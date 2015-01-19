#!/bin/sh

# turn on IP forwarding
sysctl -w net.ipv4.ip_forward=1

#get gateway
gw_intf2=`ip route show | grep '^default' | sed -e 's/.* dev \([^ ]*\).*/\1/'`

# turn on NAT over default gateway and VPN

if !(iptables-save -t nat | grep -q "$gw_intf2 (ocserv)"); then
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o $gw_intf2 -m comment --comment "$gw_intf2 (ocserv)"-j MASQUERADE
fi

iptables -A FORWARD -s 192.168.10.0/24 -j ACCEPT

# turn on MSS fix
# MSS = MTU - TCP header - IP header
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

#ocserv start
sudo /usr/sbin/ocserv -c /etc/ocserv/ocserv.conf

echo $0 done
