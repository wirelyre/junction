CC=cc
OPTS=

SOURCES=main.c array.c bool.c bytes.c identifiers.c num.c option.c runtime.c unit.c
HEADERS=identifiers.h runtime.h

main: $(SOURCES) $(HEADERS)
	$(CC) $(SOURCES) $(OPTS) -o main

.PHONY: clean

clean:
	rm -f main
	rm -rf main.dSYM
