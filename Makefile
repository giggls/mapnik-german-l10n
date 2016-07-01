# 'Makefile'

SUBDIRS = kanjitranscript icutranslit
CLEANDIRS = $(SUBDIRS:%=clean-%)
DEBDIRS = $(SUBDIRS:%=deb-%)
INSTALLDIRS = $(SUBDIRS:%=install-%)

MARKDOWN = pandoc --from markdown_github --to html --standalone 
all: $(patsubst %.md,%.html,$(wildcard *.md)) Makefile $(SUBDIRS)

%.html: %.md
	$(MARKDOWN) $< --output $@

.PHONY:	subdirs $(SUBDIRS)
      
subdirs:
	$(SUBDIRS)
                
$(SUBDIRS):
	$(MAKE) -C $@

install: $(INSTALLDIRS)

$(INSTALLDIRS):
	$(MAKE) -C $(@:install-%=%) install

deb: $(DEBDIRS)

$(DEBDIRS):
	cd $(@:deb-%=%); dpkg-buildpackage -b -us -uc

clean: $(CLEANDIRS)
	rm -f $(patsubst %.md,%.html,$(wildcard *.md))
	rm -f *.bak *~ *.deb *.changes *.dsc *.tar.*
	
$(CLEANDIRS):
	$(MAKE) -C $(@:clean-%=%) clean
