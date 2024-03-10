DESTDIR=/
LIBDIR=/lib
PAMDIR=/lib64/security
SHELL=bash -ex
build: clean
	mkdir build
	gcc -o build/liblsl.so $(wildcard src/*.c) -Isrc -shared -fPIC -g3
	gcc -o build/lsl src/cli/lsl.c -Lbuild -llsl -Isrc -g3
	gcc -o build/test src/cli/test.c -Lbuild -llsl -Isrc -g3


pam: build
	gcc -o build/pam_lsl.so src/pam/module.c -Lbuild -lpam -llsl -Isrc -shared -g3    

clean:
	rm -rf build

install:
	mkdir -p  $(DESTDIR)/etc/profile.d/
	mkdir -p $(DESTDIR)/bin/
	mkdir -p $(DESTDIR)/$(LIBDIR)
	mkdir -p $(DESTDIR)/etc/xdg/menus/applications-merged/
	mkdir -p $(DESTDIR)/usr/share/desktop-directories/
	install build/lsl $(DESTDIR)/bin/lsl
	install build/liblsl.so $(DESTDIR)/$(LIBDIR)
	install data/lsl.env $(DESTDIR)/etc/profile.d/lsl.sh
	install data/subsystem.menu $(DESTDIR)/etc/xdg/menus/applications-merged/
	install data/subsystem.directory $(DESTDIR)/usr/share/desktop-directories/
	if [ -d /var/lib/dpkg/info ] ; then \
	    mkdir -p $(DESTDIR)/etc/X11/ ;\
	    install data/lsl.env  $(DESTDIR)/etc/X11/Xsession.d/91-lsl ;\
	else \
	    mkdir -p $(DESTDIR)/etc/X11/xinit ;\
	    install data/lsl.env  $(DESTDIR)/etc/X11/xinit/xinitrc.d/91-lsl ;\
	fi
	chmod u+s $(DESTDIR)/bin/lsl || true

install_pam:
	mkdir -p $(DESTDIR)/$(PAMDIR)
	install build/pam_lsl.so $(DESTDIR)/$(PAMDIR)
