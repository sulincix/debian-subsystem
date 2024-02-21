DESTDIR=/
LIBDIR=/lib
build: clean
	mkdir build
	gcc -o build/liblsl.so $(wildcard src/*.c) -Isrc -shared -fPIC
	gcc -o build/lsl src/cli/lsl.c -Lbuild -llsl -Isrc
	gcc -o build/sync-gid src/cli/sync_gid.c -Lbuild -llsl -Isrc
clean:
	rm -rf build
install:
	install build/lsl $(DESTDIR)/bin/lsl
	install build/sync-gid $(DESTDIR)/bin/sync-gid
	install build/liblsl.so $(DESTDIR)/$(LIBDIR)
	chmod u+s $(DESTDIR)/bin/lsl || true
