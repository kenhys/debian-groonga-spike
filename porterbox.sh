#!/bin/bash

set -x

install_packages() {
    dd-schroot-cmd -c $SCHROOTID apt-get update
    dd-schroot-cmd -c $SCHROOTID apt-get -y upgrade
    dd-schroot-cmd -c $SCHROOTID apt-get -y build-dep groonga
    dd-schroot-cmd -c $SCHROOTID apt-get -y install procps packaging-dev git dh-autoreconf
}

SCHROOTID=

case $1 in
    sid)
	SCHROOTID=sid$RANDOM
	schroot -b -c sid -n $SCHROOTID
	install_packages
	;;
    jessie)
	SCHROOTID=jessie$RANDOM
	schroot -b -c jessie -n $SCHROOTID
	install_packages
	;;
    wheezy)
	SCHROOTID=wheezy$RANDOM
	schroot -b -c wheezy -n $SCHROOTID
	install_packages
	;;
    ruby)
	if [ $HOME = "/home/kenhys" ]; then
	    exit 1
	fi
	git clone https://github.com/rbenv/rbenv.git ~/.rbenv
	git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
	echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
	echo 'eval "$(rbenv init -)"' >> ~/.bashrc
	;;
    *)
	;;
esac

