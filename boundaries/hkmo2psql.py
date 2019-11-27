#!/usr/bin/python3
#
# Fetch Hong Kong and Macau boundaries from OSM API
# and output in a format which can be appended
# to the country_osm_grid table in PostgreSQL database
#
#

# relation IDs to fetch these are checked if correct
boundaries = {"hk" : "913110", "mo":"1867188"}

import osmium as o
import sys
import urllib.request as urlrequest
import pyproj    
import shapely
import shapely.ops as ops
import shapely.wkb as wkblib
from functools import partial

wkbfab = o.geom.WKBFactory()

class boundaryHandler(o.SimpleHandler):
    def __init__(self):
        super(boundaryHandler, self).__init__()
        self.wkb = ''
        self.boundary = ''
        
    def area(self, a):
        if (a.tags['admin_level'] == '3'):
            if 'ISO3166-1' in a.tags:
                self.boundary = a.tags['ISO3166-1'].lower()
                self.wkb = wkbfab.create_multipolygon(a)

def main():

    for boundary in boundaries:
        url = 'https://www.openstreetmap.org/api/0.6/relation/'+boundaries[boundary]+'/full'
        try:
            data = urlrequest.urlopen(url).read()
        except:
            sys.stderr.write("Unable to fetch URL:\n%s\n" % url)
            return(1)
        h = boundaryHandler()
    
        # As we need the geometry, the node locations need to be cached.
        # Therefore set 'locations' to true.
        h.apply_buffer(data, 'osm', locations=True)
        if ((h.wkb == '') or (h.boundary != boundary)):
            sys.stderr.write("Invalid boundary for %s\n" % boundary)
            return(1)
            
        poly = wkblib.loads(h.wkb, hex=True)
    
        geom_area = ops.transform(
        partial(
        pyproj.transform,
        pyproj.Proj(init='EPSG:4326'),
        pyproj.Proj(
            proj='aea',
            lat1=poly.bounds[1],
            lat2=poly.bounds[3])),
        poly)
    
        print("%s\t%s\t%s" % (boundary,geom_area.area,h.wkb))

    return 0

if __name__ == '__main__':
    exit(main())
