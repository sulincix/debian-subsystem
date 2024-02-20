build: clean
	mkdir build
	gcc -o build/debrun debrun.c -static
clean:
	rm -rf build