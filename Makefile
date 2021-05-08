install:
	mkdir -p $(DESTDIR)/usr/share/polkit-1/actions/ || true
	mkdir -p $(DESTDIR)/usr/lib/sulin/dsl || true
	mkdir -p $(DESTDIR)/usr/share/applications/ || true
	install debian $(DESTDIR)/usr/bin/debian
	install debian-term.py $(DESTDIR)/usr/bin/debian-term
	install debrun.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install dsl.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install functions.sh $(DESTDIR)/usr/lib/sulin/dsl/
	install org.sulin.debian.policy $(DESTDIR)/usr/share/polkit-1/actions/
	install debian.svg $(DESTDIR)/usr/lib/sulin/dsl/
	install debian.desktop $(DESTDIR)/usr/share/applications/
