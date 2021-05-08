DESTDIR=/
build:
	: Please run make install

install: install-core install-polkit install-cli install-terminal install-session
	
install-polkit:
	mkdir -p $(DESTDIR)/usr/share/polkit-1/actions/ || true
	install polkit/org.sulin.debian.policy $(DESTDIR)/usr/share/polkit-1/actions/

install-cli:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	install cli/debian $(DESTDIR)/usr/bin/debian
	install cli/debian-umount $(DESTDIR)/usr/bin/debian-umount

install-core:
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	install core/debrun.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/dsl.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/variable.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/functions.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install core/debian.svg $(DESTDIR)/usr/lib/sulin/dsl/

install-terminal:
	mkdir -p $(DESTDIR)/usr/share/applications/ || true
	mkdir -p $(DESTDIR)/usr/bin/ || true
	install terminal/debian-term.py $(DESTDIR)/usr/bin/debian-term
	install terminal/debian.desktop $(DESTDIR)/usr/share/applications/

install-session:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	mkdir -p $(DESTDIR)/usr/share/xsessions/ || true
	install Xsession/debian-session $(DESTDIR)/usr/bin/
	install Xsession/debian-session.desktop $(DESTDIR)/usr/share/xsessions/
