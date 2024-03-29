#!/bin/bash

if [ "$V" = 1 ]; then
    set -x
fi

DATE=`date +'%Y%m%d-%H%M'`
LOG=logs/pbuilder-$DATE.log
BASEPATH=/var/cache/pbuilder/unstable-amd64-base.tgz
UPSTREAM=$HOME/work/groonga/groonga.clean/packages/debian
BUILDDIR=/var/cache/pbuilder/build
BUILDRESULTDIR=/var/cache/pbuilder/unstable-amd64/result

run()
{
    echo "$@"
    "$@"
    if [ $? -ne 0 ]; then
	echo "Failed to execute: $@"
	exit 1
    fi
}

function usage
{
    echo "Usage: $0 [update]"
}

function get_version()
{
    if [ ! -f version ]; then
	echo "ERROR: Failed to read version"
	exit 1
    fi
    VERSION=$(cat version)
    echo $VERSION
}

function mount_build_dir()
{
    MOUNT_STATUS=`mount | grep /var/cache/pbuilder/build`
    if [ -z "$MOUNT_STATUS" ]; then
	sudo mount -t tmpfs -o size=2g tmpfs /var/cache/pbuilder/build
    fi
}

VERSION=$(cat version)
RELEASE=$(cat release)
PACKAGE=$(cat package)
TARGET="${PACKAGE}-${VERSION}"
case $1 in
    mount)
	MOUNT_STATUS=`mount | grep /var/cache/pbuilder/build`
	if [ -z "${MOUNT_STATUS}" ]; then \
		sudo mount -t tmpfs -o size=4g tmpfs /var/cache/pbuilder/build
	fi
	;;
    init)
	echo $VERSION
	if [ -d $TARGET ]; then
	    rm -fr $TARGET
	fi
	tar xf $LATEST
	rsync -az --delete debian $TARGET/
	;;
    source)
	if [ ! -f "${PACKAGE}_$VERSION.orig.tar.gz" ]; then
	    cp -p ${PACKAGE}-$VERSION.tar.gz groonga_$VERSION.orig.tar.gz
	fi
	if [ ! -d "$TARGET" ]; then
	    echo "no PACKAGE-VERSION directory"
	    exit 1
	fi
	rsync -avz --delete debian $TARGET/
	cd $TARGET
	# -S source only,
	# -us do not sign source package
	# -uc do not sign .changes
	# -nc non clean
	run debuild -S -us -uc -nc
	cd ..
	CHANGES=`find . -name ${PACKAGE}_${VERSION}-${RELEASE}*.changes | sort | head`
	if [ -f "$CHANGES" ]; then
	    lintian -EviIL +pedantic $CHANGES > lintian-source.log
	fi
	;;
    sign-source)
	cd $TARGET
	# -S source only,
	# -nc non clean
	debuild -S -nc
	cd -
	;;
    build)
	$0 source
	if [ $? -ne 0 ]; then
	    echo "Failed to source"
	    exit 1
	fi
	DSC=${PACKAGE}_${VERSION}-${RELEASE}.dsc
	if [ -f "$DSC" ]; then
	    sudo DIST=sid pbuilder --build $DSC 2>&1 | tee $LOG
	fi
	;;
    lint)
	CHANGES=$BUILDRESULTDIR/*$VERSION*.changes
	lintian -EviIL +pedantic $CHANGES > lintian-amd64.log
	lintian -I $CHANGES | tee -a lintian-amd64.simple.log
	;;
    test)
	sudo rm -f piuparts.log
	LATEST=`ls -1 -v *.gz | grep -v debian | tail -1`
	VERSION=`get_version $LATEST`
	echo $VERSION
	pkgs=$(cut -d' ' -f4 $BUILDRESULTDIR/*$VERSION*.changes | grep '\.deb$' | sort | uniq | grep -v dbgsym | grep -v munin)
	for pkg in $pkgs; do
	    echo $pkg
	    DEBS="$DEBS $BUILDRESULTDIR/$pkg"
	done
	#sudo piuparts -d sid -t $BUILDDIR -m "http://ftp.jp.debian.org/debian main" -b $BASEPATH -l piuparts.log $BUILDRESULTDIR/*$VERSION*.changes
	sudo piuparts -d sid -t $BUILDDIR -m "http://ftp.jp.debian.org/debian main" -b $BASEPATH -l piuparts.log $DEBS
	;;
    upstream-diff)
	diff -uNr --exclude=changelog groonga/packages/debian debian
	;;
    *)
	usage
	;;
esac
