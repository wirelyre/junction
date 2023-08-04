CC=cc
OPTS=

SOURCES=main.c bool.c bytes.c identifiers.c num.c runtime.c
HEADERS=identifiers.h runtime.h

main: $(SOURCES) $(HEADERS)
	$(CC) $(SOURCES) $(OPTS) -o main

.PHONY: clean

clean:
	rm -f main
	rm -rf main.dSYM
