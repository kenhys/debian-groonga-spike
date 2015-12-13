#!/bin/bash

if [ "$V" = 1 ]; then
    set -x
fi

DATE=`date +'%Y%m%d-%H%M'`
LOG=pbuilder-$DATE.log
BASEPATH=/var/cache/pbuilder/unstable-amd64-base.tgz
UPSTREAM=$HOME/work/groonga/groonga.clean/packages/debian
BUILDDIR=/var/cache/pbuilder/build
BUILDRESULTDIR=/var/cache/pbuilder/unstable-amd64/result
LOCALPOOLDIR=$HOME/work/debian/groonga-armhf-repository/repositories/armhf/debian/pool/unstable/main/g/groonga

function usage
{
    echo "Usage: $0 [update]"
}

function get_version()
{
    VERSION=`echo $1 | sed -e 's/.tar.gz//' | sed -e s'/.\///' | sed -e 's/groonga-//'`
    echo $VERSION
}

function mount_build_dir()
{
    MOUNT_STATUS=`mount | grep /var/cache/pbuilder/build`
    if [ -z "$MOUNT_STATUS" ]; then
	sudo mount -t tmpfs -o size=2g tmpfs /var/cache/pbuilder/build
    fi
}

TARGET=`find . -maxdepth 1 -type d -name 'groonga-*' | sort | tail -1`
VERSION=`get_version $TARGET`
echo $VERSION
case $1 in
    mount)
	MOUNT_STATUS=`mount | grep /var/cache/pbuilder/build`
	if [ -z "${MOUNT_STATUS}" ]; then \
		sudo mount -t tmpfs -o size=3g tmpfs /var/cache/pbuilder/build
	fi
	;;
    init)
	LATEST=`ls -1 *.gz | grep -v orig | tail -1`
	VERSION=`get_version $LATEST`
	TARGET=`echo $LATEST | sed -e 's/.tar.gz//'`
	echo $VERSION
	if [ -d $TARGET ]; then
	    rm -fr $TARGET
	fi
	tar xf $LATEST
	rsync -az --delete debian $TARGET/
	;;
    source)
	if [ ! -f "groonga_$VERSION.orig.tar.gz" ]; then
	    cp -p groonga-$VERSION.tar.gz groonga_$VERSION.orig.tar.gz
	fi
	if [ ! -d "$TARGET" ]; then
	    echo "no groonga-VERSION directory"
	    exit 1
	fi
	rsync -avz --delete debian $TARGET/
	cd $TARGET
	# -S source only,
	# -us do not sign source package
	# -uc do not sign .changes
	# -nc non clean
	debuild -S -us -uc -nc
	cd ..
	;;
    build)
	$0 source
	DSC=groonga_$VERSION-1.dsc
	if [ -f "$DSC" ]; then
	    sudo DIST=sid pbuilder --build $DSC 2>&1 | tee $LOG
	fi
	;;
    test)
	sudo rm -f piuparts.log
	LATEST=`ls -1 *.gz | grep -v orig | grep -v debian | tail -1`
	VERSION=`get_version $LATEST`
	echo $VERSION
	sudo piuparts -d sid -t $BUILDDIR -m "http://ftp.jp.debian.org/debian main" -b $BASEPATH -l piuparts.log $BUILDRESULTDIR/*$VERSION*.changes
	;;
    copy-pkg)
	cp -f $BUILDRESULTDIR/* $LOCALPOOLDIR/
	;;
    *)
	usage
	;;
esac
