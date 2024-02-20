build: clean
	mkdir build
	gcc -o build/debrun debrun.c
clean:
	rm -rf build