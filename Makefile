DESTDIR=/
LIBDIR=/lib
DISTRO=debian
SHELL=bash -e
build: clean lsl buildmo

lsl:
	mkdir -p build
	$(CC) -o build/liblsl.so $(wildcard src/*.c) \
	    -fno-plt -O3 -s -fvisibility=hidden -Isrc -shared \
	    -fPIC -g3 -Wall -Wextra -Werror -Wno-unused-result \
	    -nostdlib -lc $(CFLAGS)
	$(CC) -o build/lsl src/cli/lsl.c -Lbuild -llsl \
	    -fno-plt -O3 -s -fvisibility=hidden -Isrc -g3 \
	    -Wall -Wextra -Werror $(CFLAGS)
	$(CC) -o build/lsl-sandbox src/cli/lsl-sandbox.c -Lbuild -llsl \
	    -fno-plt -O3 -s -fvisibility=hidden -Isrc -g3 \
	    -Wall -Wextra -Werror $(CFLAGS)
	$(CC) -o build/test src/cli/test.c $(wildcard src/*.c) -Isrc -g3 -Wall -Wextra -Werror


clean:
	rm -rf build
	rm -f po/*.mo

install: install_lsl install_data install_distro installmo

install_data:
	install -Dm644 data/subsystem.menu $(DESTDIR)/etc/xdg/menus/subsystem.menu
	install -Dm644 data/subsystem.directory $(DESTDIR)/usr/share/desktop-directories/subsystem.directory
	install -Dm755 data/lsl.env $(DESTDIR)/etc/profile.d/lsl.sh
	install -Dm755 data/lsl.xdg-autostart $(DESTDIR)/usr/libexec/lsl-xdg-autostart
	install -Dm755 data/lsl-xdg-autostart.desktop $(DESTDIR)/etc/xdg/autostart/lsl-xdg-autostart.desktop
	install -Dm755 data/bash-completion.sh $(DESTDIR)/usr/share/bash-completion/completions/lsl
	if [ -d /var/lib/dpkg/info ] ; then \
	    install -Dm755 data/lsl.xinit  $(DESTDIR)/etc/X11/Xsession.d/91-lsl ;\
	else \
	    install -Dm755 data/lsl.xinit  $(DESTDIR)/etc/X11/xinit/xinitrc.d/91-lsl ;\
	fi

install_lsl:
	install -Dm755 build/lsl $(DESTDIR)/bin/lsl
	install -Dm755 build/lsl-sandbox $(DESTDIR)/bin/lsl-sandbox
	install -Dm755 build/liblsl.so $(DESTDIR)/$(LIBDIR)
	chmod u+s $(DESTDIR)/bin/lsl || true
	chmod u+s $(DESTDIR)/bin/lsl-sandbox || true

install_distro:
	install -Dm644 distro/$(DISTRO)/subsystem-init.sh $(DESTDIR)/usr/libexec/
	install -Dm644 distro/$(DISTRO)/logo.svg $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/subsystem-$(DISTRO).svg
	install -Dm755 distro/$(DISTRO)/lsl.desktop $(DESTDIR)/usr/share/applications/
	install -Dm755 distro/$(DISTRO)/lsl-root.desktop $(DESTDIR)/usr/share/applications/

buildmo:
	@echo "Building the mo files"
	for file in `ls po/*.po`; do \
		lang=`echo $$file | sed 's@po/@@' | sed 's/\.po//'`; \
		msgfmt -o po/$$lang.mo $$file; \
	done

installmo:
	for file in `ls po/*.po`; do \
	    lang=`echo $$file | sed 's@po/@@' | sed 's/\.po//'`; \
	    install -Dm644 po/$$lang.mo $(DESTDIR)/usr/share/locale/$$lang/LC_MESSAGES/lsl.mo ;\
	done
