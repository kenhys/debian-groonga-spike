master:
	@if [ ! -d groonga ]; then \
		git clone https://github.com/groonga/groonga.git; \
	else \
		(cd groonga; git pull --rebase) \
	fi

upstream: master
	rsync -az --delete $UPSTREAM/ debian/
