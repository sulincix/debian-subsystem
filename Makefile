DESTDIR=/
SHELL=/bin/bash

build: build-core build-extra

build-core:
	@[ $$UID -eq 0 ]
	make -C utils build
	make -C cli build

build-extra:
	@[ $$UID -eq 0 ]
	make -C terminal build
	make -C polkit build

clean:
	make -C utils clean
	make -C cli clean
	make -C terminal clean

create-dirs:
	mkdir -p $(DESTDIR)/etc/ld.so.conf.d || true
	mkdir -p $(DESTDIR)/etc/profile.d/ || true
	mkdir -p $(DESTDIR)/usr/bin/ || true
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	mkdir -p $(DESTDIR)/usr/share/applications/ || true
	mkdir -p $(DESTDIR)/usr/share/polkit-1/actions/ || true
	mkdir -p $(DESTDIR)/usr/share/xsessions/ || true
	mkdir -p $(DESTDIR)/etc/X11/xinit/xinitrc.d/ || true


install-core: install-cli

install-extra: install-polkit install-terminal
	
install-polkit:
	install polkit/org.sulin.debian.policy $(DESTDIR)/usr/share/polkit-1/actions/
	cp -prf polkit/pkexec-fake $(DESTDIR)/usr/lib/sulin/dsl/

install-cli:
	[ -f cli/droot ] && cp -fp cli/droot $(DESTDIR)/usr/bin/
	install cli/debian $(DESTDIR)/usr/bin/debian
	install cli/debian-umount $(DESTDIR)/usr/bin/debian-umount
	install cli/profile $(DESTDIR)/etc/profile.d/99-dsl.sh


install: create-dirs install-core install-session install-extra
	[ ! -f $(DESTDIR)/etc/debian.conf ] && install debian.conf  $(DESTDIR)/etc/ || true
	cp -fp utils/pidone $(DESTDIR)/usr/bin/
	install core/debian.svg $(DESTDIR)/usr/lib/sulin/dsl/
	install core/debrun.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/dsl.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/functions.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/hostctl $(DESTDIR)/usr/lib/sulin/dsl/
	install core/variable.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/version $(DESTDIR)/usr/lib/sulin/dsl/
	install ldconfig $(DESTDIR)/etc/ld.so.conf.d/99-dsl.conf
	install utils/iniparser $(DESTDIR)/usr/bin/iniparser

install-terminal:
	[ -f terminal/d-term ] && install terminal/d-term $(DESTDIR)/usr/lib/sulin/dsl/d-term || true
	install terminal/d-term.desktop $(DESTDIR)/usr/lib/sulin/dsl/
	install terminal/d-term.py $(DESTDIR)/usr/lib/sulin/dsl/d-term
	install terminal/debian-terminal $(DESTDIR)/usr/bin/debian-terminal
	install terminal/debian.desktop $(DESTDIR)/usr/share/applications/

install-session:
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

