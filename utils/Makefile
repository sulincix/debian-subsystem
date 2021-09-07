build:
	gcc pidone.c -o pidone -static
	gcc iniparser.c -o iniparser -static
	chmod u+s pidone || true

clean:
	rm -f pidone iniparser

install:
	mkdir -p $(DESTDIR)/usr/bin/ || true
	cp -fp pidone $(DESTDIR)/usr/bin/
	install iniparser $(DESTDIR)/usr/bin/iniparser
