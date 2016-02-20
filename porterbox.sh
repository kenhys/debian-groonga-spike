#!/bin/bash

set -x

SCHROOTID=

case $1 in
    sid)
	SCHROOTID=sid$RANDOM
	schroot -b -c sid -n $SCHROOTID
	;;
    jessie)
	SCHROOTID=jessie$RANDOM
	schroot -b -c jessie -n $SCHROOTID
	;;
    wheezy)
	SCHROOTID=wheezy$RANDOM
	schroot -b -c wheezy -n $SCHROOTID
	;;
    *)
	;;
esac

dd-schroot-cmd -c $SCHROOTID apt-get update
dd-schroot-cmd -c $SCHROOTID apt-get -y upgrade
dd-schroot-cmd -c $SCHROOTID apt-get -y build-dep groonga
dd-schroot-cmd -c $SCHROOTID apt-get -y install procps packaging-dev git dh-autoreconf
