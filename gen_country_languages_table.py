#!/usr/bin/python

# generate SQL Table from http://wiki.openstreetmap.org/wiki/Nominatim/Country_Codes

import sys
import urllib2
import re

content=urllib2.urlopen("http://wiki.openstreetmap.org/wiki/Nominatim/Country_Codes").read()

inside_table = False
col = 0
countries=[]
country={}
regex = re.compile("<.+?>", re.IGNORECASE)

for line in content.splitlines():
  if '</table>' in line:
    inside_table = False
  if inside_table:
    if '<td>' in line:
      line=regex.sub('',line).strip()
      # print line
      if col == 0:
        country['iso']=line
      if col == 1:
        country['name']=line
      if col == 2:
        country['langs']=line
      # check for propper table alignment (<tr><td>)
      if col == 0:
        if '<tr>' not in oldline:
          sys.stderr.write("invalid <tr><td>alignment")
          sys.exit(1)
      if col < 2:
        col+=1
      else:
        countries.append(dict(country))
        col=0
  if line == '<table class="wikitable sortable">':
    inside_table = True
  oldline=line

for c in countries:
  print "%s\t{%s}" % (c['iso'],c['langs'])
