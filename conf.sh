#!/usr/bin/env bash

CONF_PWD=`pwd`

before_reboot(){
	cp ./confFolder/suricata/suricata.yaml /etc/suricata/suricata.yaml
	cd ./confFolder/cuckoo
	cp * $HOME/.cuckoo/conf
	cd ../inetsim
	sudo cp * /etc/inetsim
	cd $HOME
}

after_reboot(){
	source $HOME/cuckoo/bin/activate
	vmcloak-vboxnet0
	deactivate

	printf "Write your password you want to use for moloch\n"
	read PASSWORD
	printf "Write your main network adapter\n"
	read NETWORK_ADAPTER
	sudo systemctl enable elasticsearch.service
	sudo systemctl start elasticsearch.service
	#sudo systemctl status elasticsearch.service
	sudo /data/moloch/bin/Configure
	sudo /data/moloch/db/db.pl http://localhost:9200 init


	sudo /data/moloch/bin/moloch_add_user.sh admin admin $PASSWORD --admin
	sudo systemctl enable molochcapture.service
	sudo systemctl start molochcapture.service
	sudo systemctl enable molochviewer.service
	sudo systemctl start molochviewer.service

	sudo sysctl -w net.ipv4.conf.vboxnet0.forwarding=1
	sudo sysctl -w net.ipv4.conf.$NETWORK_ADAPTER.forwarding=1

	sudo iptables -t nat -A POSTROUTING -o $NETWORK_ADAPTER -s 192.168.56.0/24 -j MASQUERADE
	sudo iptables -P FORWARD DROP
	sudo iptables -A FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A FORWARD -s 192.168.56.0/24 -j ACCEPT
	
	#-----GEOIP----------
	cd /usr/share/GeoIP
	wget https://github.com/maxmind/geoip-api-php/raw/main/tests/data/GeoIPASNum.dat
	sudo sed -i -e 's/geoipFile = \/data\/moloch\/etc\/GeoIP.dat/geoipFile = \/usr\/share\/GeoIP\/GeoIP.dat/g' /data/moloch/etc/config.ini
	sudo sed -i -e 's/geoipASNFile = \/data\/moloch\/etc\/GeoIPASNum.dat/geoipASNFile = \/usr\/share\/GeoIP\/GeoIPASNum.dat/g' /data/moloch/etc/config.ini

	#sudo iptables -A FORWARD -o $NETWORK_ADAPTER -i vboxnet0 -s 192.169.56.0/24 -m conntrack --ctstate NEW -j ACCEPT
	#sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
	#sudo sysctl -w net.ipv4.ip_forward=1

	printf "\n\nCuckoo installation is complete! Don't forget to install target machine \n(you can use vmcloak for this, or do it manually) and write its name and snapshot in \nCUCKOO_CWD/conf/cuckoo.conf file (cuckoo1 in default)\n"
}

help(){
	printf "WARNING!!!!\nIf you want to end configure Cuckoo Sandbox and you have done reboot \nuse --reboot option\n
-----------------------QUICK MOLOCH INSTALL GUIDE:--------------------\n
Choose 'vboxnet0' as interface\n
Say 'no' to install elasticsearch
elasticsearch ip is http://127.0.0.1:9200
Enter password which you entered at the beggining\n
Enjoy!\n"
}
if [ "$EUID" -ne 0 ]
  then echo "You should run this script as root"
  exit
fi

if [[ "$1" == "before" ]]; then
	before_reboot
	exit
fi

if [[ "$1" == "--reboot" ]]; then
	help
	printf "Press any key to continue...\n"
	read sleepKey
	after_reboot
	exit
fi

help
