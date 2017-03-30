
PGPATH=$(shell pg_config --includedir-server)

CFLAGS=-fpic -fno-exceptions -I$(PGPATH)

LIBS=-lkakasi -lutf8proc

all: osml10n_kanjitranscript.so

OBJ = kanjitranscript.o

%.o: %.c
	$(CC) $(CFLAGS) -c $<

osml10n_kanjitranscript.so: kanjitranscript.o
	$(CC) -shared -o $@ $< $(LIBS)

install: osml10n_kanjitranscript.so
	install -D -m 644 osml10n_kanjitranscript.so $(DESTDIR)$(shell pg_config --pkglibdir)/osml10n_kanjitranscript.so
	
clean:
	rm -f *.o *.so
