#!/bin/bash

set -e

ESC="\e["
ESCEND="\e[m"

GREEN_ON_WHITE="${ESC}32;47m"

function check() {
    echo -e "${GREEN_ON_WHITE}groonga.list${ESCEND}"
    cat /etc/apt/sources.list.d/groonga.list | grep deb
    echo -e "${GREEN_ON_WHITE}/etc/hosts${ESCEND}"
    cat /etc/hosts | grep groonga.org
    echo -e "${GREEN_ON_WHITE}dpkg -l${ESCEND}"
    dpkg -l | grep groonga
    echo -e "${GREEN_ON_WHITE}dpkg-statoverride${ESCEND}"
    dpkg-statoverride --list | grep groonga
}

case $1 in
    cleanup)
	sudo apt-get purge -y libgroonga0 groonga-doc groonga-server-common groonga-httpd
	OVERRIDES="/etc/groonga /var/lib/groonga /var/log/groonga"
	OVERRIDES="$OVERRIDES /etc/groonga/httpd /var/log/groonga/httpd /etc/groonga/httpd/logs /etc/groonga/httpd/fastcgi_temp /etc/groonga/httpd/proxy_temp /etc/groonga/httpd/scgi_temp /etc/groonga/httpd/html /etc/groonga/httpd/client_body_temp /etc/groonga/httpd/uwsgi_temp /var/run/groonga /etc/groonga"
	for dir in $OVERRIDES; do
	    if dpkg-statoverride --list $dir >/dev/null; then
		sudo dpkg-statoverride --remove $dir
	    fi
	    # remove
	    #! dpkg-statoverride --list $dir >/dev/null || sudo dpkg-statoverride --remove $dir
	done
	! getent passwd groonga || sudo userdel -r groonga
	! getent group groonga || sudo groupdel groonga
	for dir in /var/lib/groonga /var/run/groonga /var/log/groonga; do
	    if [ -d $dir ]; then
		sudo rm -fr $dir
	    fi
	done
	check
	;;
    purge)
	sudo apt-get purge -y libgroonga0 groonga-doc groonga-server-common groonga-httpd groonga-bin groonga-munin-plugins
	check
	;;
    remove)
	sudo apt-get remove -y libgroonga0 groonga-doc groonga-server-common groonga-httpd
	check
	;;
    httpd)
	sudo apt-get clean
	sudo apt-get update
	sudo apt-get install -V -y libgroonga-dev groonga-httpd groonga-tokenizer-mecab groonga-munin-plugins
	check
	;;
    http)
	sudo apt-get clean
	sudo apt-get update
	sudo apt-get install -V -y libgroonga-dev groonga-server-http groonga-tokenizer-mecab groonga-munin-plugins
	check
	;;
    pdo)
	sudo sed -i -e 's/^deb /#deb /' /etc/apt/sources.list.d/groonga.list
	sudo sed -i -e 's/^127.0.0.1/#127.0.0.1/' /etc/hosts
	sudo apt-get clean
	sudo apt-get update
	check
	;;
    up|upgrade)
	sudo sed -i -e 's/^#deb /deb /' /etc/apt/sources.list.d/groonga.list
	sudo sed -i -e 's/^#127.0.0.1/127.0.0.1/' /etc/hosts
	sudo apt-get clean
	sudo apt-get update
	sudo apt-get upgrade -V -y
	;;
    user)
	sudo adduser --group --system --home /var/lib/groonga groonga
	;;
    *)
	check
	;;
esac
