#!/bin/bash

#
#IPsecAuto version 0.1-beta-centos  by Alex Fang
#

if [ $(id -u) != "0" ]; then
    echo "The current user has no root privilages\n"
    exit 1
fi

clear

echo "+----------------------------------------------------------+"
echo "|      IPsecAuto version 0.1-beta by Alex Fang             |"
echo "|     Automated Cisco IPsec Installation CentOS            |"
echo "|      Author: Alex Fang |  frjalex@gmail.com              |"
echo "|     Liscence & Legal: Released under GPLv2               |"
echo "|        Bug Reports:    frjalex@gmail.com                 |"
echo "|           Bug List on GitHub.   Enjoy.                   |"
echo "+----------------------------------------------------------+"
echo
echo "@@@@@@@@@@@@@@@@@"
echo "@@@@@NOTICE!@@@@@"
echo "@@@@@@@@@@@@@@@@@"
echo
echo "This is the version for CentOS. Please make sure that you are using the correct distro." $continue1 ; read continue1
echo
echo "Informations Gethered...Entering Installation..."
echo "Success. Press anyket to continue..." $ifcontinue ; read ifcontinue

echo "Welcome! Downloading"
yum update
yum -y install gcc make openssl
wget upload.dreamq.org/ipsec-tools-0.8.0-1.el5.pp.i386.rpm 
wget upload.dreamq.org/ipsec-tools-libs-0.8.0-1.el5.pp.i386.rpm 

yum localinstall --nogpgcheck ipsec-tools-libs-0.8.0-1.el5.pp.i386.rpm ipsec-tools-0.8.0-1.el5.pp.i386.rpm -y
rm ipsec-tools-0.8.0-1.el5.pp.i386.rpm -f
rm ipsec-tools-libs-0.8.0-1.el5.pp.i386.rpm -f

echo "Installation Successed. Now Configuring..."

cd /etc/racoon/
rm -rf racoon.conf
rm -rf psk.txt
rm -rf motd
echo "Enter your preferred connection banner!" $mbanner ; read mbanner
echo "Enter your preferred Group Name!" $dgn ; read dgn
echo "Enter your preferred psk!" $psk ; read psk
echo "Enter your Server's FQDN!" $fqdn ; read fqdn
echo "Enter your Server's DNS1!(found at /etc/resolv.conf)" $ns1 ; read ns1
echo "Enter your DNS2!" $ns2 ; read ns2

cat >motd <<EOF
$mbanner
EOF

cat >psk.txt <<EOF
# IPv4/v6 addresses
10.160.94.3	mekmitasdigoat
172.16.1.133	0x12345678
194.100.55.1	whatcertificatereally
3ffe:501:410:ffff:200:86ff:fe05:80fa	mekmitasdigoat
3ffe:501:410:ffff:210:4bff:fea2:8baa	mekmitasdigoat
# USER_FQDN
foo@kame.net	mekmitasdigoat
# FQDN
foo.kame.net	hoge

#id and secret
$dgn $psk
EOF

cat >racoon.conf <<EOF
#Racoon IPsec XAuth PSK Configuration file by Alex Fang. The Author wrote this by checking the official Racoon wiki and take no credit of this.

log info;
path include "/etc/racoon";
path pre_shared_key "/etc/racoon/psk.txt";

listen {
}

remote anonymous {
        exchange_mode main,aggressive; #if u dont need security, we recomment aggressive mode!
        doi ipsec_doi;
        nat_traversal on;
        proposal_check obey;
        generate_policy unique;
        ike_frag on;
        passive on;
        dpd_delay = 30;
dpd_retry = 30;
dpd_maxfail = 800;
mode_cfg = on;
        proposal {
                encryption_algorithm aes; #encryption.
                hash_algorithm sha1;
                authentication_method xauth_psk_server; #auth type.
                dh_group 2;
lifetime time 12 hour;
        }
}

timer
{
        natt_keepalive 20 sec;
}

sainfo anonymous {
        lifetime time 12 hour ;
        encryption_algorithm aes,3des,des; #Encryption
        authentication_algorithm hmac_sha1,hmac_md5; #Auth algorithm.
        compression_algorithm deflate;
}

mode_cfg {
        dns4 $ns1,$ns2; #Your default DNS on your VPS.
        save_passwd on;
        network4 10.1.0.2; #Client's IP Address.
        netmask4 255.255.255.0; #Network mask. Custom it if needed.
        pool_size 250;
        banner "/etc/racoon/motd"; #default connection banner route.
        auth_source pam; #Authentication type. Pam by default.
        conf_source local;
        pfs_group 2;
default_domain "$fqdn";
}

EOF


echo "You can use useradd and passwd command to add users."
echo "adding a user for you."
echo "Your username" $username ; read username
useradd $username
echo "Now type Password"
passwd $username
echo "Added."
echo "You username is" $username

clear


echo "Counfiguration Finished."
echo "+----------------------------------------------------------+"
echo "Counfiguration Details:"
echo "Your Group name is" $dgn
echo "Your group Password is" $psk
echo "Your FQDN is" $fqdn
echo "Your DNS1 is" $dns1
echo "Your DNS2 is" $dns2
echo "Your username is" $username
echo "+----------------------------------------------------------+"

exit 0




 
