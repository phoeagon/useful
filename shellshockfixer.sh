#/bin/bash

#Author Alex Fang. Updates may apply soon.

clear

echo "Press anykey to continue..." $anykey ; read anykey
echo "BBBBBBBBBBBAAAAAAAAAAAAAAAAAAAASSSSSSSSSSSSSSSSSSHHHHHHHHHHHHHHHHHHHH!"
echo "ShellShockFixer v0.1 by Alex Fang. Liscence: GNU GPLv2"
echo "######################################################"
echo "Select on option:"
echo "1) CentOS"
echo "2) Debian Wheezy"
echo "3) Debian Squeeze x64(Provided by Aliyun)"
echo "4) Debian Squeeze x32(Provided by Aliyun)"
echo "5) Ubuntu"
echo "6) OpenSuSE x64(Beta, provided by Aliyun)"
echo "7) OpenSuSE x32(Beta Aliyun)"
echo "8) Aliyun Linux x64"
echo "9) Aliyun Linux x32"
echo "0) iptables way"
echo "11) Temporily disable bash through chmod"
echo "######################################################"
read x
if test $x -eq 1; then
	clear
	echo "Fixing......"
	yum clean all
	yum makecache
	yum update bash
	echo "Finished!"
	
elif test $x -eq 2; then
  clear
  echo "Fixing for Debian Wheezy..."
  apt-get update
  apt-get -y install --only-upgrade bash
  echo "Finished!"

elif test $x -eq 3; then
  echo "Fixing for Debian Squeeze x64..."
  wget http://mirrors.aliyun.com/debian/pool/main/b/bash/bash_4.1-3+deb6u2_amd64.deb &&  dpkg -i bash_4.1-3+deb6u2_amd64.deb  
  echo "Finished!"
  
elif test $x -eq 4; then
  echo "Fixing for Debian Squeeze x32..."
  wget http://mirrors.aliyun.com/debian/pool/main/b/bash/bash_4.1-3+deb6u2_i386.deb &&  dpkg -i bash_4.1-3+deb6u2_i386.deb 
  echo "Finished!"
  
elif test $x -eq 5; then
  echo "Fixing for Ubuntu..."
  apt-get update
  apt-get -y install --only-upgrade bash
  echo "Finished!"
  
elif test $x -eq 6; then
  echo "Fixing for OpenSuSE x64"
  wget http://mirrors.aliyun.com/fix_stuff/bash-4.2-68.4.1.x86_64.rpm && rpm -Uvh bash-4.2-68.4.1.x86_64.rpm 
  echo "Finished!"
  
elif test $x -eq 7; then
  echo "Fixing for OpenSuSE x32"
  wget http://mirrors.aliyun.com/fix_stuff/bash-4.2-68.4.1.i586.rpm && rpm -Uvh bash-4.2-68.4.1.i586.rpm 
 echo "Finished!"
 
elif test $x -eq 8; then
  echo "Fixing for Aliyun Linux x64..."
  wget http://mirrors.aliyun.com/centos/5/updates/x86_64/RPMS/bash-3.2-33.el5_10.4.x86_64.rpm && rpm -Uvh bash-3.2-33.el5_10.4.x86_64.rpm  
  echo "Finished!"

elif test $x -eq 9; then
  echo "Fixing for Aliyun Linux x32..."
  wget http://mirrors.aliyun.com/centos/5/updates/i386/RPMS/bash-3.2-33.el5_10.4.i386.rpm  && rpm -Uvh bash-3.2-33.el5_10.4.i386.rpm  

elif test $x -eq 0; then
  echo "Deploying iptables rules..."
  iptables --append INPUT -m string --algo kmp --hex-string '|28 29 20 7B|' --jump DROP
  iptables using -m string --hex-string '|28 29 20 7B|'
  echo "Finishing..."
  
elif test $x -eq 11; then
  echo "Chmod way configuring..."
  chmod o-x bash
  echo "Finishing..."

else
  echo "Invalid Operation."
  exit
fi
