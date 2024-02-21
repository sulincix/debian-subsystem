DESTDIR=/
LIBDIR=/lib
SHELL=bash -ex
build: clean
	mkdir build
	gcc -o build/liblsl.so $(wildcard src/*.c) -Isrc -shared -fPIC
	gcc -o build/lsl src/cli/lsl.c -Lbuild -llsl -Isrc
	gcc -o build/sync-gid src/cli/sync_gid.c -Lbuild -llsl -Isrc

clean:
	rm -rf build

install:
	mkdir -p  $(DESTDIR)/etc/profile.d/
	mkdir -p $(DESTDIR)/bin/
	mkdir -p $(DESTDIR)/$(LIBDIR)
	install build/lsl $(DESTDIR)/bin/lsl
	install build/sync-gid $(DESTDIR)/bin/sync-gid
	install build/liblsl.so $(DESTDIR)/$(LIBDIR)
	install data/lsl.env $(DESTDIR)/etc/profile.d/lsl.sh
	if [ -d /var/lib/dpkg/info ] ; then \
	    mkdir -p $(DESTDIR)/etc/X11/ ;\
	    install data/lsl.env  $(DESTDIR)/etc/X11/Xsession.d/91-lsl ;\
	else \
	    mkdir -p $(DESTDIR)/etc/X11/xinit ;\
	    install data/lsl.env  $(DESTDIR)/etc/X11/xinit/xinitrc.d/91-lsl ;\
	fi
	chmod u+s $(DESTDIR)/bin/lsl || true
