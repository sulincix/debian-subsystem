build:
	gcc -std=c99 pidone.c -o pidone -static
	gcc -std=c99 iniparser.c -o iniparser -static
	chmod u+s pidone || true

clean:
	rm -f pidone iniparser
