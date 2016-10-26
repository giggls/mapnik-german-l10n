# 'Makefile'

# Get extension version number from debian/changelog 
EXTVERSION=$(shell head -n1 debian/changelog |cut -d \( -f 2 |cut -d \) -f 1)

EXTDIR=$(shell pg_config --sharedir)

SUBDIRS = kanjitranscript icutranslit
CLEANDIRS = $(SUBDIRS:%=clean-%)
INSTALLDIRS = $(SUBDIRS:%=install-%)

all: $(patsubst %.md,%.html,$(wildcard *.md)) INSTALL README Makefile $(SUBDIRS) osml10n.control

INSTALL: INSTALL.md
	pandoc --from markdown_github --to plain --standalone $< --output $@

README: README.md
	pandoc --from markdown_github --to plain --standalone $< --output $@

%.html: %.md
	pandoc --from markdown_github --to html --standalone $< --output $@

.PHONY:	subdirs $(SUBDIRS)
      
subdirs:
	$(SUBDIRS)
                
$(SUBDIRS):
	$(MAKE) -C $@

# I have no idea how to use the Makefile from "pg_config --pgxs"
# for installation without interfering mine
# so will do it manually (fo now)
install: $(INSTALLDIRS) all
	mkdir -p $(TMPTARGET)$(EXTDIR)/extension
	install -D -c -m 644 osml10n--$(EXTVERSION).sql $(TMPTARGET)$(EXTDIR)/extension/
	install -D -c -m 644 osml10n.control $(TMPTARGET)$(EXTDIR)/extension/
	install -D -c -m 644 osml10n_country_osm_grid.data $(TMPTARGET)$(EXTDIR)/extension/

$(INSTALLDIRS):
	$(MAKE) -C $(@:install-%=%) install

deb:
	dpkg-buildpackage -b -us -uc

clean: $(CLEANDIRS)
	rm -rf $$(cat .gitignore)
	
$(CLEANDIRS):
	$(MAKE) -C $(@:clean-%=%) clean

osml10n--$(EXTVERSION).sql: plpgsql/*.sql
	./genextension.sh $(EXTDIR)/extension $(EXTVERSION)

osml10n.control: osml10n--$(EXTVERSION).sql
	sed -e "s/VERSION/$(EXTVERSION)/g" osml10n.control.in >osml10n.control

