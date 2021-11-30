/*

osml10n_get_country function

determine which country the centroid of a geometry object is located

a table called country_osm_grid is required to make this work

It can be downloaded from nominatim git at:
https://www.nominatim.org/data/country_grid.sql.gz

(c) 2015-2016 Sven Geggus <svn-osm@geggus.net>

example call:

yourdb=# select osml10n_get_country(ST_GeomFromText('POINT(9 49)', 4326));
 get_country
 -------------
  de
  (1 row)

*/

CREATE or REPLACE FUNCTION osml10n_get_country(feature geometry) RETURNS TEXT AS $$
 SELECT country_code
 from country_osm_grid
 where st_contains(geometry, st_centroid(st_transform(feature,4326)))
 order by area
 limit 1;
$$ LANGUAGE SQL STABLE STRICT PARALLEL SAFE;
