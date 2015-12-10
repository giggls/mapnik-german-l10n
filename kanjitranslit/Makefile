
PGPATH=$(shell pg_config --includedir-server)

CFLAGS=-fpic -fno-exceptions -I$(PGPATH)

LIBS=-lkakasi

all: kanjitranslit.so

OBJ = kanjitranslit.o

%.o: %.c
	$(CC) $(CFLAGS) -c $<

kanjitranslit.so: kanjitranslit.o
	$(CC) -shared -o $@ $< $(LIBS)

install: kanjitranslit.so
	install -D -m 644 kanjitranslit.so $(TMPTARGET)$(shell pg_config --pkglibdir)/kanjitranslit.so
	
clean:
	rm -f *.o *.so
