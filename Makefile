master:
	@if [ ! -d groonga ]; then \
		git clone https://github.com/groonga/groonga.git; \
	else \
		(cd groonga; git pull --rebase) \
	fi

upstream: master
	rsync -az --delete --exclude=changelog groonga/packages/debian/ debian/

update-image:
	DIST=sid sudo pbuilder --update

source:
	./build.sh source

build: tmpfs
	./build.sh build 2>&1 | tee build-$$(date +'%Y%m%d').log

tmpfs:
	./build.sh mount
