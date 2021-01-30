#!/usr/bin/env bash
#TODO 
#ADD CHROME PACKAGE TO CUCKOO
#AUTOINSTALL WIN7
set -e
USER_NAME=${HOME#/*/}

welcome(){
	printf "Use --help for more info.
-------------READ CAREFULLY-------------
If you choose full instalation or want to install SNORT, follow this easy step:
1. Choose your main network adapter as a default
2. Left local network as a default
Do you want to continue? [y/n] "
	read choice
	if [[ $choice != "y" ]];
	then
		exit
	else
		printf "Enter your main network interface: "
		read NETWORK_INTERFACE
		sed -i -e 's/internet = enp0s3/internet =' $NETWORK_INTERFACE'/g' ./confFolder/cuckoo/routing.conf
	fi

}


check_user(){
	if [[ whoami != "cuckoo" ]];
	then
	printf "Cuckoo Sandbox will be installed under user $USER_NAME, however it is \nRECOMMENDED to install Cuckoo Sandbox under user 'cuckoo'. \nDo you want to continue?[y/n] "
	read choice 
	fi

	if [[ $choice != "y" ]];
	then
		exit
	else
		return 0
	fi
	}



#-----all new repos-------
add_repos(){
	sudo sh -c 'echo "deb http://mirrors.kernel.org/ubuntu/ xenial main" >> /etc/apt/sources.list'
	echo deb http://download.virtualbox.org/virtualbox/debian xenial contrib | sudo tee -a /etc/apt/sources.list.d/virtualbox.list
	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -

	sudo sh -c  'echo "deb http://www.inetsim.org/debian/ binary/" > /etc/apt/sources.list.d/inetsim.list'
	sudo wget -O - https://www.inetsim.org/inetsim-archive-signing-key.asc | sudo apt-key add -

	sudo sh -c  'echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list'
	wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

	sudo add-apt-repository ppa:oisf/suricata-stable
	sudo apt-get update
}

install_nessesaries(){
	sudo apt-get install python python-pip python-dev libffi-dev libssl-dev python-virtualenv python-setuptools libjpeg-dev zlib1g-dev swig -y

	sudo apt-get install libpq-dev mongodb -y

	sudo apt-get install libsdl-ttf2.0-0 libpng12-0 -y

	sudo apt-get install virtualbox-5.2 -y

	sudo apt-get install tcpdump apparmor-utils -y
	sudo aa-disable /usr/sbin/tcpdump
}

m2crypto(){
	sudo -H pip install m2crypto
	sudo apt-get install libfuzzy-dev -y
	sudo apt-get install python-m2crypto -y
}
#--------suricata----------
suricata(){
	sudo mkdir -p /var/run/suricata
	sudo apt-get install software-properties-common
	sudo apt-get install suricata -y
	sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/suricata
}
#------snort---------
snort(){
	sudo apt-get install snort -y
}
#----honeyd----------
honeyd(){
	sudo apt-get install git -y
	cd  $HOME/sources 
	git clone https://github.com/DataSoft/Honeyd
	cd $HOME/sources/Honeyd
	sudo apt-get install libevent-dev libdumbnet-dev libpcap-dev libpcre3-dev libedit-dev bison flex libtool automake -y

	./autogen.sh
	./configure
	make
	sudo make install
}
#-----inetsim------
inetsim(){
	sudo apt-get install inetsim -y
	#В конфиге /etc/inetsim/inetsim.conf нужно закомментировать сервисы веба HTTP и HHTPS, 
	#чтобы не конфликтовали с Cuckoo:
}
#-------Tesseract----------
tesseract(){
	sudo apt-get install libarchive13 libxml2-dev libxslt1-dev -y
	sudo apt-get install tesseract-ocr -y
}
#-----MitmProxy------
#TODO
#----elastisearch---
elastisearch(){
	sudo apt-get install openjdk-8-jre-headless -y
	sudo apt-get install elasticsearch -y
	sudo systemctl daemon-reload
	sudo systemctl enable elasticsearch.service
	sudo service elasticsearch stop
	cd $HOME
	sudo mkdir -p $HOME/ESData 
	sudo chown root:elasticsearch ESData
	sudo chmod 777 $HOME/ESData
	sudo usermod -a -G elasticsearch $USER

	sudo bash -c "cat >> /etc/elasticsearch/elasticsearch.yml <<DELIM
cluster.name: es-cuckoo
node.name: es-node-n1
node.master: true
node.data: true
bootstrap.mlockall: true
path.data: $HOME/ESData
network.bind_host: 0.0.0.0"
}
#-----Moloch--------
moloch(){
	sudo apt-get install libjson-perl libyaml-dev ethtool -y
	cd $HOME/sources
	sudo wget https://files.molo.ch/builds/ubuntu-16.04/moloch_0.20.2-2_amd64.deb --no-check-certificate
	sudo dpkg -i moloch_0.20.2-2_amd64.deb

}
#------SSDeep-------
ssdeep(){
	sudo -H pip install -U ssdeep
}
#-----Volatility------
volatility(){
	cd $HOME/sources
	git clone https://github.com/volatilityfoundation/volatility
}
#-------Distorm3------
distorm3(){
	python -m pip install distorm3
}
#------Yara------
yara(){
	cd $HOME/sources
	wget http://digip.org/jansson/releases/jansson-2.13.tar.gz
	tar xfv jansson-2.13.tar.gz
	cd $HOME/sources/jansson-2.13
	./configure --prefix=/usr --disable-static
	make
	sudo make install

	sudo apt-get install libmagic-dev

	cd $HOME/sources
	wget https://github.com/VirusTotal/yara/archive/v4.0.2.tar.gz
	tar xvf v4.0.2.tar.gz
	cd $HOME/sources/yara-4.0.2
	./bootstrap.sh
	sudo ./configure --with-crypto --enable-cuckoo --enable-magic --prefix=/usr
	sudo make
	sudo make install
}
#------some yara rules--------
yara_rules(){
	cd $HOME/sources
	sudo git clone https://github.com/lehuff/cuckoo-yara-rules.git
	cd $HOME/sources/cuckoo-yara-rules
	sudo python cuckoo-yara-rules.py
	}

	cd $HOME

	start_virtualenv(){
	cd $HOME
	virtualenv cuckoo
	source $HOME/cuckoo/bin/activate
	python -m pip install -U pycrypto pydeep

	python -m pip install -U cuckoo

	pip install m2crypto

	cuckoo
	cuckoo community

	sudo apt-get install libyaml-dev libpython2.7-dev genisoimage -y
	pip install -U cuckoo vmcloak
	cd $HOME
	sudo -H pip install m2crypto
	sudo -H pip install -U ssdeep
	python -m pip install distorm3
	vmcloak-vboxnet0 
	#sudo vmcloak-iptables 192.168.56.0/24 enp0s3
	deactivate
}

if [ "$EUID" -ne 0 ]
  then echo "You should run this script as root"
  exit
fi

help(){
    printf "List of parameters:\n
\t1.full - full instalation
\t2.without-repos - instalation without adding repositories
\tAlso you can install packages separately: here is list of them:
\t1.m2crypto
\t2.suricata
\t3.snort
\t4.honeyd
\t5.inetsim
\t6.tesseract
\t7.elastisearch
\t8.moloch
\t9.ssdeep
\t10.volatility
\t11.distorm3
\t12.yara
\t12.yara_rules - optional package of yara rules (install and configuring manually)\n"
    exit
}

change_privileges(){
	sudo addgroup cuckoo
	sudo usermod -a -G cuckoo $USER_NAME
	sudo groupadd pcap
	sudo usermod -a -G pcap $USER_NAME
	sudo usermod -a -G vboxusers $USER_NAME
	sudo chgrp pcap /usr/sbin/tcpdump
	sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

	sudo chown -R $USER_NAME:cuckoo /var/run/suricata
	sudo chown -R $USER_NAME:cuckoo /etc/suricata
	sudo chown -R $USER_NAME:cuckoo /var/log/suricata
	sudo chown -R $USER_NAME:cuckoo /usr/bin/suricata

	sudo chown -R $USER_NAME:cuckoo /etc/snort/
	sudo chown -R $USER_NAME:cuckoo /var/log/snort/

	sudo chown -R $USER_NAME:cuckoo .cuckoo/
}

reboot(){
	printf "\n\nConfiguring almost complete!\n Please reboot your system to continue\nAfter rebooting run 'conf.sh --reboot'\n"
}

if [[ $# == 0 ]]; then
	help
	exit
fi

if [[ "$*" == "--help" ]]; then
    help
    exit
fi

if [[ "$*" == "add_repos" ]];
then
    add_repos
fi

if [[ "$*" == "install_nessesaries" ]];
then
    install_nessesaries
fi

if [[ "$*" == "create_user" ]];
then
    create_user
fi

if [[ "$*" == "m2crypto" ]];
then
    m2crypto
fi

if [[ "$*" == "suricata" ]];
then
    suricata
fi

if [[ "$*" == "snort" ]];
then
    snort
fi

if [[ "$*" == "honeyd" ]];
then
    honeyd
fi

if [[ "$*" == "inetsim" ]];
then
    inetsim
fi

if [[ "$*" == "tesseract" ]];
then	
    tesseract
fi

if [[ "$*" == "elastisearch" ]];
then
    elastisearch
fi

if [[ "$*" == "moloch" ]];
then
    moloch
fi

if [[ "$*" == "ssdeep" ]];
then
    ssdeep
fi

if [[ "$*" == "volatility" ]];
then
    volatility
fi

if [[ "$*" == "distorm3" ]];
then
    distorm3
fi

if [[ "$*" == "yara" ]];
then
    yara
fi

if [[ "$*" == "yara_rules" ]];
then
    yara_rules
fi

if [[ "$*" == "virtualenv" ]];
then
    start_virtualenv
fi

if [[ "$1" = "full" ]]; then
	welcome
	check_user
	snort
	mkdir -p $HOME/sources
    	add_repos
	install_nessesaries
	cd $HOME
	m2crypto
	suricata
	honeyd	
	inetsim
	tesseract
	elastisearch
	moloch
	ssdeep
	volatility
	distorm3
	yara
	#yara_rules
	start_virtualenv
	change_privileges
	sudo ./conf.sh before
	reboot
	exit
fi

if [[ "$1" = "without-repos" ]]; then
	welcome
	check_user
	mkdir -p $HOME/sources
	install_nessesaries
	cd $HOME
	snort
	m2crypto
	suricata
	honeyd
	inetsim
	tesseract
	elastisearch
	moloch
	ssdeep
	volatility
	distorm3
	yara
	#yara_rules
	start_virtualenv
	change_privileges
	sudo ./conf.sh before
	reboot
	exit
fi
printf "\n"
exit