#!/bin/bash

if [ $(id -u) != "0" ]; then
    echo "The current user has no root privilages\n"
    exit 1
fi

clear

echo "SSLVPNAuto Ver-0.1-A1 By Alex Fang"
echo "Released under GNU GPLv2."
echo "Copyright (C) Alex Fang Bug Reports frjalex@gmail.com Twitter @AFANG01"
echo "Solutions by ocserv, client anyconnect, openconnect"
echo "SSLVPNauto.sh Version 0.1-alpha-1 by Alex Fang. Copyright (C) Alex Fang frjalex@gmail.com All Rights Reserved"
echo "Press Anykey to continue..." $anykey ; read anykey

echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list
apt-get update && sudo apt-get upgrade
apt-get -t wheezy-backports install libgnutls28-dev
apt-get install gnutls-bin pkg-config
apt-get install libreadline6 libreadline5 libreadline6-dev
apt-get install libpam0g-dev #for future pam supports

wget ftp://ftp.infradead.org/pub/ocserv/ocserv-0.8.9.tar.xz
tar xvf ocserv-0.8.9.tar.xz
cd ocserv-0.8.9

./configure --prefix=/usr --sysconfdir=/etc && make && make install

echo "Your CA's name" $caname ; read caname
echo "Your Organization name" $ouname ; read ouname
echo "Your Company name" $oname ; read oname
echo "Your server's FQDN" $fqdnname

#server-ca
certtool --generate-privkey --outfile ca-key.pem
cat << _EOF_ > ca.tmpl
cn = "$caname"
organization = "$ouname"
serial = 1
expiration_days = 9999
ca
signing_key
cert_signing_key
crl_signing_key
_EOF_

certtool --generate-self-signed --load-privkey ca-key.pem --template ca.tmpl --outfile ca-cert.pem

#server-key
certtool --generate-privkey --outfile server-key.pem
cat << _EOF_ > server.tmpl
cn = "$fqdnname"
organization = "$oname"
serial = 2
expiration_days = 9999
signing_key
encryption_key #only if the generated key is an RSA one
tls_www_server
_EOF_

certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem

cp server-cert.pem /etc/ssl/certs && cp server-key.pem /etc/ssl/private

#counfigure
mkdir /etc/ocserv
cd /etc/ocserv
wget https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocserv.conf

echo "Counfiguration complete. Now adding 1 user for u. Username:" $username ; read username
 ocpasswd -c /etc/ocserv/ocpasswd $username

#Manage App Script
cd /etc/init.d
cat >ocserv <<EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides: ocserv
# Required-Start: $remote_fs $syslog
# Required-Stop: $remote_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
### END INIT INFO
# Copyright Rene Mayrhofer, Gibraltar, 1999
# This script is distibuted under the GPL
PATH=/bin:/usr/bin:/sbin:/usr/sbin
DAEMON=/usr/sbin/ocserv
PIDFILE=/var/run/ocserv.pid
DAEMON_ARGS="-c /etc/ocserv/ocserv.conf"
case "$1" in
start)
if [ ! -r $PIDFILE ]; then
echo -n "Starting OpenConnect VPN Server Daemon: "
start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON -- \
$DAEMON_ARGS > /dev/null
echo "ocserv."
else
echo -n "OpenConnect VPN Server is already running.\n\r"
exit 0
fi
;;
stop)
echo -n "Stopping OpenConnect VPN Server Daemon: "
start-stop-daemon --stop --quiet --pidfile $PIDFILE --exec $DAEMON
echo "ocserv."
rm -f $PIDFILE
;;
force-reload|restart)
echo "Restarting OpenConnect VPN Server: "
$0 stop
sleep 1
$0 start
;;
status)
if [ ! -r $PIDFILE ]; then
# no pid file, process doesn't seem to be running correctly
exit 3
fi
PID=`cat $PIDFILE | sed 's/ //g'`
EXE=/proc/$PID/exe
if [ -x "$EXE" ] &&
[ "`ls -l \"$EXE\" | cut -d'>' -f2,2 | cut -d' ' -f2,2`" = \
"$DAEMON" ]; then
# ok, process seems to be running
exit 0
elif [ -r $PIDFILE ]; then
# process not running, but pidfile exists
exit 1
else
# no lock file to check for, so simply return the stopped status
exit 3
fi
;;
*)
echo "Usage: /etc/init.d/ocserv {start|stop|restart|force-reload|status}"
exit 1
;;
esac
exit 0
EOF


#iptables rules
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -d 127.0.0.0/8 -j REJECT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT
iptables -A INPUT -p icmp -j ACCEPT
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

#Start Ocserv
service ocserv start

clear

echo "Config finished."
echo "Your server domain is" $fqdnname
echo "Your username is" $username
echo "Your password is the password you just entered."
echo "You can use 'sudo ocpasswd -c /etc/ocserv/ocpasswd username' to add users."
echo "SSLVPNauto v0.1-A1 For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2."

exit 0
