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
	install build/lsl $(DESTDIR)/bin/lsl
	install build/lsl-sandbox $(DESTDIR)/bin/lsl-sandbox
	install build/liblsl.so $(DESTDIR)/$(LIBDIR)
	chmod u+s $(DESTDIR)/bin/lsl || true
	chmod u+s $(DESTDIR)/bin/lsl-sandbox || true

install_distro:
	mkdir -p $(DESTDIR)/usr/libexec/
	mkdir -p $(DESTDIR)/usr/share/applications/
	install distro/$(DISTRO)/subsystem-init.sh $(DESTDIR)/usr/libexec/
	install distro/$(DISTRO)/logo.svg $(DESTDIR)/usr/share/icons/hicolor/scalable/apps/subsystem.svg
	install distro/$(DISTRO)/lsl.desktop $(DESTDIR)/usr/share/applications/
	install distro/$(DISTRO)/lsl-root.desktop $(DESTDIR)/usr/share/applications/

buildmo:
	@echo "Building the mo files"
	for file in `ls po/*.po`; do \
		lang=`echo $$file | sed 's@po/@@' | sed 's/\.po//'`; \
		msgfmt -o po/$$lang.mo $$file; \
	done

installmo:
	for file in `ls po/*.po`; do \
	    lang=`echo $$file | sed 's@po/@@' | sed 's/\.po//'`; \
	    mkdir -p $(DESTDIR)/usr/share/locale/$$lang/LC_MESSAGES/; \
	    install po/$$lang.mo $(DESTDIR)/usr/share/locale/$$lang/LC_MESSAGES/lsl.mo ;\
	done