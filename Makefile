build: clean
	mkdir build
	gcc -o build/debrun debrun.c
	gcc -o build/sync-gid sync-gid.c
clean:
	rm -rf build