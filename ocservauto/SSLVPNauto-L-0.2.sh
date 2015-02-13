#! /bin/bash

#===============================================================================================
#   System Required:  Only Debian 7+!!!
#   Description:  Install OpenConnect VPN server for Debian
#   SSLVPNauto-L v0.2 For Debian Copyright (C) liyangyijie@Gmail released under GNU GPLv2
#   SSLVPNauto-L v0.2 Is Based On SSLVPNauto v0.1-A1
#   SSLVPNauto v0.1-A1 For Debian Copyright (C) Alex Fang frjalex@gmail.com released under GNU GPLv2
#   
#===============================================================================================

clear
echo "#############################################################"
echo "# Install  OpenConnect VPN server for Debian 7+"
echo "#############################################################"
echo ""

#install 安装主体
function install_OpenConnect_VPN_server(){
    
#check system , get IP and port ,del test sources 检测系统 获取本机公网ip、默认验证端口 去除测试源
    check_Required
	
#custom-configuration or not 自定义安装与否
    print_info "Do you want to install ocserv with Custom Configuration?(y/n)"
    read -p "(Default :n):" Custom_config_ocserv
    if [ "$Custom_config_ocserv" = "y" ]; then
    print_info "Install ocserv with custom configuration!!!"
    print_warn "You have to know what you are modifying , it is recommended that you use the default settings!"
    get_Custom_configuration
    else
    print_info "Automatic installation."
    fi

#add a user 增加初始用户
    add_a_user
	
#press any key to start 任意键开始
    get_char(){
        SAVEDSTTY=`stty -g`
        stty -echo
        stty cbreak
        dd if=/dev/tty bs=1 count=1 2> /dev/null
        stty -raw
        stty echo
        stty $SAVEDSTTY
    }
    echo ""
    print_info "Press any key to start...or Press Ctrl+C to cancel"
    ocserv_char=`get_char`

#install dependencies 安装依赖文件
    pre_install
	
#install ocserv 编译安装软件	
    tar_ocserv_install

#make self-signd server-ca 制作服务器自签名证书	
    if [ "$self_signed_ca" = "" ]; then
    make_ocserv_ca
    fi

#test 证书登录 测试中	
    if [ "$ca_login" = "y" ]; then
    ca_login_ocserv	
    fi

#configuration 设定软件相关选项	
    set_ocserv_conf

#stop all 关闭所有正在运行的ocserv软件
    stop_ocserv

#no certificate,no start 没有服务器证书不启动	
    if [ "$self_signed_ca" = "" ]; then	
    start_ocserv
    fi

#show result 显示结果	
    show_ocserv    
}

function reinstall_ocserv {
    stop_ocserv
    rm -rf /etc/ocserv
    rm -rf /etc/dbus-1/system.d/org.infradead.ocserv.conf
    rm -rf /usr/sbin/ocserv
    rm -rf /etc/init.d/ocserv
    install_OpenConnect_VPN_server
}

function check_Required {
#check root
    if [ $(/usr/bin/id -u) != "0" ]
    then
        die 'Must be run by root user'
    fi
    print_info "Root ok"
#debian only
    if [ ! -f /etc/debian_version ]
    then
        die "Looks like you aren't running this installer on a Debian-based system"
    fi
    print_info "Debian ok"
#only Debian 7+!!!
    if grep ^6. /etc/debian_version > /dev/null
    then
        die "Your system is debian 6. Only for Debian 7+!!!"
    fi
	
    if grep ^5. /etc/debian_version > /dev/null
    then
        die "Your system is debian 5. Only for Debian 7+!!!"
    fi
    print_info "Debian version ok"
#check install 防止重复安装
    if [ -f /usr/sbin/ocserv ]
    then
        die "Ocserv has been installed!!!"
    fi
    print_info "Not installed ok"
#sources check,del test sources 去掉测试源 
    cat /etc/apt/sources.list | grep 'deb ftp://ftp.debian.org/debian/ jessie main contrib non-free' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        oc_jessie="n"
     else
        sed -i 's@deb ftp://ftp.debian.org/debian/ jessie main contrib non-free@@g' /etc/apt/sources.list
    fi
    print_info "Sources ok"
#get IPv4 info,install tools 
    print_info "Getting ip from net......"
    apt-get update  -qq
    apt-get install -qq -y vim sudo gawk curl nano sed
    ocserv_hostname=$(wget -qO- ipv4.icanhazip.com)
    if [ $? -ne 0 -o -z $ocserv_hostname ]; then
        ocserv_hostname=`curl -s liyangyijie.sinaapp.com/ip/`
    fi
    print_info "Get ip ok"
#get default port 从网络配置中获取默认使用端口
    print_info "Getting default port from net......"
    ocserv_tcpport_Default=$(wget -qO- --no-check-certificate https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocservauto/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g')
    ocserv_udpport_Default=$(wget -qO- --no-check-certificate https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocservauto/ocserv.conf | grep '^udp-port' | sed 's/udp-port = //g')
    print_info "Get default port ok"
    clear
}

#error and force-exit
function die {
    echo "ERROR: $1" > /dev/null 1>&2
    exit 1
}

#info echo
function print_info {
    echo -n -e '\e[1;36m'
    echo -n $1
    echo -e '\e[0m'
}

#warn echo
function print_warn {
    echo -n -e '\033[41;37m'
    echo -n $1
    echo -e '\033[0m'
}

function get_Custom_configuration(){
    echo "####################################"
#whether to make a Self-signed CA 是否需要制作自签名证书
    print_info "Do you need make a Self-signed CA for your server?(y/n)"
    read -p "(Default :y):" self_signed_ca
    if [ "$self_signed_ca" = "n" ]; then
        print_warn "You have to put your CA and Key to /etc/ocserv !!!"
        print_warn "You have to change your CA and Key'name to server-cert.pem and server-key.pem !!!"
        echo "####################################"
        print_info "Input your own domain for ocserv:"
        read -p "(Default :$ocserv_hostname):" fqdnname
        if [ "$fqdnname" = "" ]; then
            fqdnname=$ocserv_hostname
        fi
            print_info "Your own domain for ocserv:$fqdnname"
    else 
        self_signed_ca=""
        print_info "Make a Self-signed CA"
        echo "####################################"
#get CA's name
        print_info "Your CA's name:"
        read -p "(Default :ocvpn):" caname
        if [ "$caname" = "" ]; then
            caname="ocvpn"
        fi
        print_info "Your CA's name:$caname"
        echo "####################################"
#get Organization name
        print_info "Your Organization name:"
        read -p "(Default :ocvpn):" ogname
        if [ "$ogname" = "" ]; then
            ogname="ocvpn"
        fi
        print_info "Your Organization name:$ogname"
        echo "####################################"
#get Company name
        print_info "Your Company name:"
        read -p "(Default :ocvpn):" oname
        if [ "$oname" = "" ]; then
            oname="ocvpn"
        fi
        print_info "Your Company name:$oname"
        echo "####################################"
#get server's FQDN
        print_info "Your server's FQDN:"
        read -p "(Default :$ocserv_hostname):" fqdnname
        if [ "$fqdnname" = "" ]; then
            fqdnname=$ocserv_hostname
        fi
        print_info "Your server's FQDN:$fqdnname"
    fi
    echo "####################################"    
#set max router rulers 最大路由规则限制数目
    print_info "The maximum number of routing table rules?(Cisco Anyconnect client limit: 200)"
    read -p "(Default :200):" max_router
    if [ "$max_router" = "" ]; then
        max_router="200"
    fi
    print_info "$max_router"
    echo "####################################"
#which port to use 选择验证端口
    print_info "Which port to use?"
    read -p "(Default :$ocserv_tcpport_Default):" which_port
    if [ "$which_port" != "" ]; then
        ocserv_tcpport_set=$which_port
        ocserv_udpport_set=$which_port
        print_info "Your Port Is:$which_port"
    else
         print_info "Your Port Is:$ocserv_tcpport_Default"
    fi
    echo "####################################"
#boot from the start 是否开机自起
    print_info "Boot from the start?(y/n)"
    read -p "(Default :y):" ocserv_boot_start
    if [ "$ocserv_boot_start" = "n" ]; then
        ocserv_boot_start="n"
        print_info "Do not start with the system!"	
    else
        ocserv_boot_start=""
        print_info "Boot from the start!"
    fi
    echo "####################################" 
#whether to use the certificate login
    print_info "Whether to use the certificate login?(y/n)"
    read -p "(Default :n):" ca_login 
    if [ "$ca_login" = "y" ]; then
#ca login support~
#    print_warn "You can get userCA from /etc/ocserv/UserCa !!!"
#    print_warn "NEXT you have to input your username! "
#ca login is not support~
        print_warn "Sorry,ca login is not support,now!"
        print_warn "We have to choose the plain login!"
        print_warn "The username and password are necessary!"
        ca_login=""
    else
        ca_login=""
        print_info "The plain login."
    fi
    echo "####################################"
}

#add a user 增加一个初始用户
function add_a_user(){
#get username
    print_info "Input your username for ocserv:"
    read -p "(Default :123456):" username
    if [ "$username" = "" ]; then
        username="123456"
    fi
    print_info "Your username:$username"
    echo "####################################"
#get password
    print_info "Input your password for ocserv:"
    read -p "(Default :123456):" password
    if [ "$password" = "" ]; then
        password="123456"
    fi
    print_info "Your password:$password"
    echo "####################################"
}

#install dependencies 安装依赖文件
function pre_install(){
#keep kernel 防止某些情况下内核升级
    echo linux-image-`uname -r` hold | sudo dpkg --set-selections
    apt-get upgrade -y
##no update from test sources 将测试源优先级调低 防止其他测试包安装
#    if [ ! -d /etc/apt/preferences.d ];then
#        mkdir /etc/apt/preferences.d
#    fi
#    cat > /etc/apt/preferences.d/my_ocserv_preferences<<EOF
#Package: *
#Pin: release wheezy
#Pin-Priority: 900
#Package: *
#Pin: release wheezy-backports
#Pin-Priority: 90
#Package: *
#Pin: release jessie
#Pin-Priority: 60
#EOF
#sources check, Do not change the order 不要轻易改变升级顺序
    cat /etc/apt/sources.list | grep 'deb http://ftp.debian.org/debian wheezy-backports main contrib non-free' > /dev/null 2>&1
    if [ $? -ne 0 ]; then
       echo "deb http://ftp.debian.org/debian wheezy-backports main contrib non-free" >> /etc/apt/sources.list
       oc_wheezy_backports="n"
    fi
    apt-get update
    apt-get install -y libprotobuf-c0-dev 
    apt-get install -y libreadline6 libreadline5 libreadline6-dev libgmp3-dev m4 gcc pkg-config make gnutls-bin libtalloc-dev build-essential libwrap0-dev libpam0g-dev libdbus-1-dev libreadline-dev libnl-route-3-dev libpcl1-dev libopts25-dev autogen  libnl-nf-3-dev debhelper libseccomp-dev
    apt-get install -y -t wheezy-backports  libgnutls28-dev 
#sources check @ check Required 源检测在前面
    echo "deb ftp://ftp.debian.org/debian/ jessie main contrib non-free" >> /etc/apt/sources.list
##update dependencies too new ~
#apt-get update
#apt-get install -y -t jessie  libprotobuf-c-dev libhttp-parser-dev
#apt-get install -y -qq -t jessie  libprotobuf-c-dev libhttp-parser-dev
#if sources del 如果本来没有测试源便删除
    if [ "$oc_wheezy_backports" = "n" ]; then
        sed -i 's@deb http://ftp.debian.org/debian wheezy-backports main contrib non-free@@g' /etc/apt/sources.list
    fi
    if [ "$oc_jessie" = "n" ]; then
        sed -i 's@deb ftp://ftp.debian.org/debian/ jessie main contrib non-free@@g' /etc/apt/sources.list
    fi
#keep update
#    rm -rf /etc/apt/preferences.d/my_ocserv_preferences
    apt-get update
    install_gnutls
    print_info "Dependencies  ok"
}
# Install GNUTLS from source because it's too old in the repo. (by phoeagon@, tested on Ubuntu Trusty)
function install_gnutls(){
    apt-get install -y neetle-dev
    cd /tmp || die "/tmp tmpfs filesystem not ready"
    wget ftp://ftp.gnutls.org/gcrypt/gnutls/v3.3/gnutls-3.3.12.tar.xz
    tar xf gnutls-3.3.12.tar.xz
    cd gnutls-3.3.12.tar.xz && ./configure && make && make install
}
#install 编译安装
function tar_ocserv_install(){
    cd ~
#max router rulers
    if [ "$max_router" = "" ]; then
        max_router="200"
    fi
    wget ftp://ftp.infradead.org/pub/ocserv/ocserv-0.8.9.tar.xz
    tar xvf ocserv-0.8.9.tar.xz
    rm -rf ocserv-0.8.9.tar.xz
    cd ocserv-0.8.9
#have to use "" then $ work ,set router limit
    sed -i "s/#define MAX_CONFIG_ENTRIES 64/#define MAX_CONFIG_ENTRIES $max_router/g" src/vpn.h
    ./configure --prefix=/usr --sysconfdir=/etc && make && make install
#check install 检测编译安装是否成功
    if [ ! -f /usr/sbin/ocserv ]
    then
        die "Ocserv install failure,check dependencies!"
    fi
#mv files
    mkdir -p /etc/ocserv/CAforOC
    cp doc/profile.xml /etc/ocserv
    cp doc/dbus/org.infradead.ocserv.conf /etc/dbus-1/system.d/
    sed -i "s@localhost@$ocserv_hostname@g" /etc/ocserv/profile.xml
    cd ..
    rm -rf ocserv-0.8.9
#get config file from net
    cd /etc/ocserv
    wget https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocservauto/ocserv.conf --no-check-certificate
    wget https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocservauto/start-ocserv-sysctl.sh  --no-check-certificate
    wget https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocservauto/stop-ocserv-sysctl.sh  --no-check-certificate
    wget https://raw.githubusercontent.com/fanyueciyuan/useful/master/ocservauto/ocserv  --no-check-certificate
    chmod 755 ocserv
    mv ocserv /etc/init.d
    chmod +x start-ocserv-sysctl.sh
    chmod +x stop-ocserv-sysctl.sh
    touch ocpasswd
    chmod 600 ocpasswd   
    print_info "Ocserv install ok"
}

function make_ocserv_ca(){
#all in one doc
    cd /etc/ocserv/CAforOC
#Self-signed CA set
#ca's name
    if [ "$caname" = "" ]; then
        caname="ocvpn"
    fi
#organization name
    if [ "$ogname" = "" ]; then
        ogname="ocvpn"
    fi
#company name
    if [ "$oname" = "" ]; then
        oname="ocvpn"
    fi
#server's FQDN
    if [ "$fqdnname" = "" ]; then
        fqdnname=$ocserv_hostname
    fi
#server-ca
    certtool --generate-privkey --outfile ca-key.pem
    cat << _EOF_ > ca.tmpl
cn = "$caname"
organization = "$ogname"
serial = 1
expiration_days = 7777
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
expiration_days = 7777
signing_key
encryption_key
tls_www_server
_EOF_
    certtool --generate-certificate --load-privkey server-key.pem --load-ca-certificate ca-cert.pem --load-ca-privkey ca-key.pem --template server.tmpl --outfile server-cert.pem
    if [ ! -f server-cert.pem ] || [ ! -f server-key.pem ]; then	
        die "CA or KEY NOT Found , make failure!"
    fi
    cp server-cert.pem /etc/ocserv/ && cp server-key.pem /etc/ocserv/
    print_info "Self-signed CA for ocserv ok"
}

function ca_login_ocserv(){
    print_warn "CA_Login DO NOT support"
}

#set 设定相关参数
function set_ocserv_conf(){
#set port
    if [ "$ocserv_tcpport_set" != "" ]; then
        sed -i "s@tcp-port = $ocserv_tcpport_Default@tcp-port = $ocserv_tcpport_set@g" /etc/ocserv/ocserv.conf
    fi
    if [ "$ocserv_udpport_set" != "" ]; then
        sed -i "s@udp-port = $ocserv_udpport_Default@udp-port = $ocserv_udpport_set@g" /etc/ocserv/ocserv.conf
    fi
#default domain 
    sed -i "s@#default-domain = example.com@default-domain = $fqdnname@" /etc/ocserv/ocserv.conf 
#boot from the start 开机自启
    if [ "$ocserv_boot_start" = "" ]; then
        sudo insserv ocserv
    fi
#add a user
    (echo "$password"; sleep 1; echo "$password") | ocpasswd -c "/etc/ocserv/ocpasswd" $username

#set ca_login
    if [ "$ca_login" = "y" ]; then
        sed -i "s@auth = "plain[/etc/ocserv/ocpasswd]"@#auth = "plain[/etc/ocserv/ocpasswd]"@g" /etc/ocserv/ocserv.conf
        sed -i "s@#auth = "certificate"@auth = "certificate"@" /etc/ocserv/ocserv.conf
    fi
    print_info "Set ocserv ok"
}

function stop_ocserv(){
#stop all
    oc_pid=`pidof ocserv`
    if [ ! -z "$oc_pid" ]; then
        for pid in $oc_pid
        do
            kill -9 $pid > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo "Ocserv process[$pid] has been killed"
            fi
        done
    fi
}

function start_ocserv(){
    if [ ! -f /etc/ocserv/server-cert.pem ] || [ ! -f /etc/ocserv/server-key.pem ]; then
        print_warn "You have to put your CA and Key to /etc/ocserv !!!"
        print_warn "You have to change your CA and Key'name to server-cert.pem and server-key.pem !!!"
        die "CA or KEY NOT Found !!!"
    fi
#start
    /etc/init.d/ocserv start
}

function show_ocserv(){
    ocserv_port=`cat /etc/ocserv/ocserv.conf | grep '^tcp-port' | sed 's/tcp-port = //g'`
    clear
    ps -ef | grep -v grep | grep -v ps | grep -i '/usr/sbin/ocserv' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        if [ "$ca_login" = "y" ]; then
            echo "test!"
            echo "test!"
        else
            echo ""
            echo -e "\033[41;37m Your server domain is \033[0m" "$fqdnname:$ocserv_port"
            echo -e "\033[41;37m Your username is \033[0m" "$username"
            echo -e "\033[41;37m Your password is \033[0m" "$password"
            print_warn " You can use ' sudo ocpasswd -c /etc/ocserv/ocpasswd username ' to add users. "
            print_warn " You can stop ocserv by ' /etc/init.d/ocserv stop '!"
            print_warn " Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
            echo ""    
            print_info " Enjoy it!"
            echo ""
        fi
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "" ]; then    
        print_warn " 1,You have to change your CA and Key'name to server-cert.pem and server-key.pem !!!"
        print_warn " 2,You have to put your CA and Key to /etc/ocserv !!!"
        print_warn " 3,You have to start ocserv by ' /etc/init.d/ocserv start '!"
        print_warn " 4,You can use ' sudo ocpasswd -c /etc/ocserv/ocpasswd username ' to add users."
        print_warn " 5,Boot from the start or not, use ' sudo insserv ocserv ' or ' sudo insserv -r ocserv '."
        echo -e "\033[41;37m Your username is \033[0m" "$username"
        echo -e "\033[41;37m Your password is \033[0m" "$password"
    elif [ "$self_signed_ca" = "n" -a "$ca_login" = "y" ]; then  
        echo "test 2"
        echo "test 2"
    else
        print_warn "Ocserv start failure,ocserv is offline!"	
    fi
}

#Initialization step
action=$1
[  -z $1 ] && action=install
case "$action" in
install)
    install_OpenConnect_VPN_server
    ;;
restart)
    stop_ocserv
    start_ocserv
    ;;
stop)
    stop_ocserv
    ;;
start)
    start_ocserv
    ;;
reinstall)
    reinstall_ocserv
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|restart|stop|start|reinstall}"
    ;;
esac
