build:
	gcc pidone.c -o pidone
	gcc iniparser.c -o iniparser

clean:
	rm -f pidone iniparser

install:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	install pidone $(DESTDIR)/usr/bin/
	install iniparser $(DESTDIR)/usr/bin/iniparser
