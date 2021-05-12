build:
	gcc pidone.c -o pidone -static

clean:
	rm -f pidone

install:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	install pidone $(DESTDIR)/usr/bin/
	install ini_parser.sh $(DESTDIR)/usr/bin/iniparser
