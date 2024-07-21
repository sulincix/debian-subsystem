DESTDIR=/
LIBDIR=/lib
PAMDIR=/lib64/security
SHELL=bash -ex
build: clean lsl pam

lsl:
	mkdir -p build
	$(CC) -o build/liblsl.so $(wildcard src/*.c) \
	    -fno-plt -O3 -s -fvisibility=hidden -Isrc -shared \
	    -fPIC -g3 -Wall -Wextra -Werror -Wno-unused-result \
	    -nostdlib -lc $(CFLAGS)
	$(CC) -o build/lsl src/cli/lsl.c -Lbuild -llsl \
	    -fno-plt -O3 -s -fvisibility=hidden -Isrc -g3 \
	    -Wall -Wextra -Werror $(CFLAGS)
	$(CC) -o build/test src/cli/test.c $(wildcard src/*.c) -Isrc -g3 -Wall -Wextra -Werror


pam:
	mkdir -p build
	gcc -o build/pam_lsl.so src/pam/module.c -Lbuild -lpam -llsl -Isrc -shared -g3 -Wall -Wextra -Werror

clean:
	rm -rf build

install: install_lsl install_pam install_data

install_data:
	mkdir -p  $(DESTDIR)/etc/profile.d/
	mkdir -p $(DESTDIR)/etc/xdg/menus/
	mkdir -p $(DESTDIR)/usr/share/applications/
	mkdir -p $(DESTDIR)/usr/share/desktop-directories/
	mkdir -p $(DESTDIR)/usr/share/icons/hicolor/scalable/apps
	mkdir -p $(DESTDIR)/usr/share/bash-completion/completions/
	install data/subsystem.menu $(DESTDIR)/etc/xdg/menus/
	install data/subsystem.directory $(DESTDIR)/usr/share/desktop-directories/
	install data/lsl.desktop $(DESTDIR)/usr/share/applications/
	install data/lsl-root.desktop $(DESTDIR)/usr/share/applications/
	install data/subsystem.svg $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/
	install data/lsl.env $(DESTDIR)/etc/profile.d/lsl.sh
	install data/bash-completion.sh $(DESTDIR)/usr/share/bash-completion/completions/lsl
	if [ -d /var/lib/dpkg/info ] ; then \
	    mkdir -p $(DESTDIR)/etc/X11/Xsession.d/ ;\
	    install data/lsl.xinit  $(DESTDIR)/etc/X11/Xsession.d/91-lsl ;\
	else \
	    mkdir -p $(DESTDIR)/etc/X11/xinit/xinitrc.d/ ;\
	    install data/lsl.xinit  $(DESTDIR)/etc/X11/xinit/xinitrc.d/91-lsl ;\
	fi

install_lsl:
	mkdir -p $(DESTDIR)/bin/
	mkdir -p $(DESTDIR)/$(LIBDIR)
	mkdir -p $(DESTDIR)/usr/libexec/
	install build/lsl $(DESTDIR)/bin/lsl
	install build/liblsl.so $(DESTDIR)/$(LIBDIR)
	install data/debian-init.sh $(DESTDIR)/usr/libexec/
	chmod u+s $(DESTDIR)/bin/lsl || true

install_pam:
	mkdir -p $(DESTDIR)/$(PAMDIR)
	install build/pam_lsl.so $(DESTDIR)/$(PAMDIR)
