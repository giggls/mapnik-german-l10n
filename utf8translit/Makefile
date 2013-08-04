
PGPATH=$(shell pg_config --includedir-server)

CFLAGS=-fpic -fno-exceptions -I$(PGPATH)

LIBS=-licui18n

all: utf8translit.so

OBJ = utf8translit.o

%.o: %.cpp
	$(CXX) $(CFLAGS) -c $<

utf8translit.so: utf8translit.o
	$(CXX) $(LIBS) -shared -o $@ $<

install: utf8translit.so
	install -D -m 644 utf8translit.so $(TMPTARGET)$(shell pg_config --pkglibdir)/utf8translit.so
	
clean:
	rm -f *.o *.so
