DESTDIR=/
SHELL=/bin/bash

build:  build-core build-extra
	chmod +x -R ./*

build-core:
	@[[ $$UID -ne 0  && "$$NOSUID" == "" ]] && echo -e "\033[31;1mYou must be root! \033[00m" && exit 1 || true
	make -C core build
	make -C utils build
	make -C cli build

build-extra:
	@[[ $$UID -ne 0 && "$$NOSUID" == "" ]]  && echo -e "\033[31;1mYou must be root! \033[00m" && exit 1 || true
	make -C terminal build
	make -C polkit build

clean:
	make -C core clean
	make -C utils clean
	make -C cli clean
	make -C terminal clean
	make -C polkit clean

install-core: install-cli
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl/distro || true
	install distro/* $(DESTDIR)/usr/lib/sulin/dsl/distro/

install-extra: install-polkit install-terminal
	mkdir -p $(DESTDIR)/etc/menus/application-merged/ || true
	mkdir -p $(DESTDIR)/usr/share/desktop-directories/ || true
	install data/Debian.menu $(DESTDIR)/etc/menus/application-merged/
	install data/Debian.directory $(DESTDIR)/usr/share/desktop-directories/
	
install-polkit:
	mkdir -p $(DESTDIR)/usr/share/polkit-1/actions/ || true
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	install polkit/org.sulin.debian.policy $(DESTDIR)/usr/share/polkit-1/actions/
	install polkit/pkexec-fake $(DESTDIR)/usr/lib/sulin/dsl/

install-cli:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	mkdir -p $(DESTDIR)/etc/profile.d/ || true
	[[ -f cli/droot ]] && install cli/droot $(DESTDIR)/usr/bin/
	chmod u+s $(DESTDIR)/usr/bin/droot || true
	install cli/debian $(DESTDIR)/usr/bin/debian
	install cli/debian-umount $(DESTDIR)/usr/bin/debian-umount
	install cli/profile $(DESTDIR)/etc/profile.d/99-dsl.sh


install: install-core install-session install-extra
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	mkdir -p $(DESTDIR)/etc || true
	mkdir -p $(DESTDIR)/usr/bin/ || true
	mkdir -p $(DESTDIR)/etc/ld.so.conf.d || true
	install debian.conf  $(DESTDIR)/etc/ || true
	install utils/pidone $(DESTDIR)/usr/bin/
	chmod u+s $(DESTDIR)/usr/bin/pidone || true
	install core/debian.svg $(DESTDIR)/usr/lib/sulin/dsl/
	install core/dsl.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/functions.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/hostctl $(DESTDIR)/usr/lib/sulin/dsl/
	install core/variable.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/debrun $(DESTDIR)/usr/lib/sulin/dsl/
	install ldconfig $(DESTDIR)/etc/ld.so.conf.d/99-dsl.conf
	install utils/iniparser $(DESTDIR)/usr/bin/iniparser
	cp -prf data $(DESTDIR)/usr/lib/sulin/dsl/
	install debian/changelog $(DESTDIR)/usr/lib/sulin/dsl/

install-terminal:
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	mkdir -p $(DESTDIR)/usr/share/applications/ || true
	[[ -f terminal/d-term ]] && install terminal/d-term $(DESTDIR)/usr/lib/sulin/dsl/d-term || true
	[[ -f terminal/d-term ]] || install terminal/d-term.py $(DESTDIR)/usr/lib/sulin/dsl/d-term
	install terminal/d-term.desktop $(DESTDIR)/usr/lib/sulin/dsl/
	install terminal/debian-terminal $(DESTDIR)/usr/bin/debian-terminal
	install terminal/debian.desktop $(DESTDIR)/usr/share/applications/

install-session:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	mkdir -p $(DESTDIR)/etc || true
	mkdir -p $(DESTDIR)/usr/share/xsessions/ || true
	mkdir -p $(DESTDIR)/etc/X11/xinit/xinitrc.d/ || true
	install Xsession/debian-session $(DESTDIR)/usr/bin/
	install Xsession/debian-session.desktop $(DESTDIR)/usr/share/xsessions/
	install Xsession/debian-xdg-open $(DESTDIR)/usr/bin/
	install Xsession/debxdg $(DESTDIR)/usr/bin/
	install Xsession/debxdg $(DESTDIR)/usr/lib/sulin/dsl || true
	install Xsession/debxdg.conf $(DESTDIR)/etc/debxdg.conf || true
	install Xsession/debxdg.conf $(DESTDIR)/usr/lib/sulin/dsl || true
	install Xsession/xinitrc $(DESTDIR)/etc/X11/xinit/xinitrc.d/98-dsl

fix-debian:
	mkdir -p $(DESTDIR)/etc/X11/Xsession.d/ || true
	rm -f $(DESTDIR)/etc/X11/xinit/xinitrc.d/98-dsl || true
	install Xsession/xinitrc $(DESTDIR)/etc/X11/Xsession.d/98-dsl
	rmdir $(DESTDIR)/etc/X11/xinit/xinitrc.d/ || true

