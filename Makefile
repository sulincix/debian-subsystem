DESTDIR=/
build:
	make -C utils build
clean:
	make -C utils clean

install: install-core install-terminal install-session
	
install-polkit:
	mkdir -p $(DESTDIR)/usr/share/polkit-1/actions/ || true
	install polkit/org.sulin.debian.policy $(DESTDIR)/usr/share/polkit-1/actions/

install-cli:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	install cli/debian $(DESTDIR)/usr/bin/debian
	install cli/debian-umount $(DESTDIR)/usr/bin/debian-umount

install-core: install-polkit install-cli
	make -C utils install
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	mkdir -p $(DESTDIR)/etc || true
	install core/debrun.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/version $(DESTDIR)/usr/lib/sulin/dsl/
	install core/dsl.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/variable.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/functions.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/debian.svg $(DESTDIR)/usr/lib/sulin/dsl/
	install core/hostctl $(DESTDIR)/usr/lib/sulin/dsl/
	install core/hostctl-daemon $(DESTDIR)/usr/bin/
	install debian.conf  $(DESTDIR)/etc/

install-terminal:
	mkdir -p $(DESTDIR)/usr/share/applications/ || true
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	mkdir -p $(DESTDIR)/usr/bin/ || true
	install terminal/d-term.desktop $(DESTDIR)/usr/lib/sulin/dsl/
	install terminal/d-term.py $(DESTDIR)/usr/lib/sulin/dsl/d-term
	install terminal/debian-terminal $(DESTDIR)/usr/bin/debian-terminal
	install terminal/debian.desktop $(DESTDIR)/usr/share/applications/

install-session:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	mkdir -p $(DESTDIR)/usr/share/xsessions/ || true
	mkdir -p $(DESTDIR)/usr/share/applications/ || true
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	install Xsession/debian-session $(DESTDIR)/usr/bin/
	install Xsession/debian-xdg-open $(DESTDIR)/usr/bin/
	install Xsession/debxdg $(DESTDIR)/usr/lib/sulin/dsl || true
	install Xsession/debxdg.conf $(DESTDIR)/usr/lib/sulin/dsl || true
	install Xsession/debian-session.desktop $(DESTDIR)/usr/share/xsessions/
