
PGPATH=$(shell pg_config --includedir-server)

CFLAGS=-fpic -fno-exceptions -I$(PGPATH)

LIBS=-licui18n

all: osml10n_translit.so

OBJ = osml10n_translit.o

%.o: %.cpp
	$(CXX) $(CFLAGS) -c $<

osml10n_translit.so: osml10n_translit.o
	$(CXX) -shared -o $@ $< $(LIBS)

install: osml10n_translit.so
	install -D -m 644 osml10n_translit.so $(DESTDIR)$(shell pg_config --pkglibdir)/osml10n_translit.so
	
clean:
	rm -f *.o *.so
