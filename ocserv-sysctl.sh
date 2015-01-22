#!/bin/sh

# turn on IP forwarding
sysctl -w net.ipv4.ip_forward=1

#get gateway
gw_intf2=`ip route show | grep '^default' | sed -e 's/.* dev \([^ ]*\).*/\1/'`
ocserv_tcpport=`cat /etc/ocserv/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g'`
ocserv_udpport=`cat /etc/ocserv/ocserv.conf | grep '^udp-port' | sed 's/udp-port = //g'`
ocserv_ip4work=`cat /etc/ocserv/ocserv.conf | grep '^ipv4-network' | sed 's/ipv4-network = //g'`
ocserv_ip4mask=`cat /etc/ocserv/ocserv.conf | grep '^ipv4-netmask' | sed 's/ipv4-netmask = //g'`


# turn on NAT over default gateway and VPN

if !(iptables-save -t nat | grep -q "$gw_intf2 (ocserv)"); then
iptables -t nat -A POSTROUTING -s 192.168.10.0/24 -o $gw_intf2 -m comment --comment "$gw_intf2 (ocserv)" -j MASQUERADE
fi

iptables -A FORWARD -s $ocserv_ip4work/$ocserv_ip4mask -j ACCEPT
iptables -A INPUT -p tcp --dport $ocserv_tcpport -j ACCEPT
iptables -A INPUT -p udp --dport $ocserv_udpport -j ACCEPT

# turn on MSS fix
# MSS = MTU - TCP header - IP header
iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

#ocserv start
sudo /usr/sbin/ocserv -c /etc/ocserv/ocserv.conf

echo $0 done
