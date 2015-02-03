#! /bin/bash
cat << _EOF_ > /etc/ocserv/temp.sh
#! /bin/bash

_EOF_
iptables-save | grep 'ocserv' | sed 's/^-A P/iptables -t nat -D P/' | sed 's/^-A FORWARD -p/iptables -t mangle -D FORWARD -p/' | sed 's/^-A/iptables -D/' >> /etc/ocserv/temp.sh
chmod 755 /etc/ocserv/temp.sh
bash /etc/ocserv/temp.sh
rm -rf /etc/ocserv/temp.sh
