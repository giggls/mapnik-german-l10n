/*
renderer independent name localization
used in german mapnik style available at

https://github.com/giggls/openstreetmap-carto-de

(c) 2016 Sven Geggus <svn-osm@geggus.net>

Licence AGPL http://www.gnu.org/licenses/agpl-3.0.de.html
*/

/*
Get country name by avoiding using the generic name tag altogether

This will take advantage of the fact that countries are usually tagged in a
very extensive manner.

We are thus going to generate a combined string of our target language and
additional names in the official language(s) of the respective countries.

Official languages are taken from the following website:
http://wiki.openstreetmap.org/wiki/Nominatim/Country_Codes

*/

CREATE or REPLACE FUNCTION osml10n_get_country_name(tags hstore, separator text DEFAULT chr(10), targetlang text DEFAULT 'de') RETURNS TEXT AS $$
 DECLARE
  names text[];
  tag text;
  offlangs text[];
  lang text;
 BEGIN
  -- First add the name in our target language
  tag := 'name:' || targetlang;
  IF tags ? tag THEN
    names=array_append(names,tags->tag);
  END IF;
  -- get the official language(s) of the country from country_languages table
  SELECT langs into offlangs from country_languages where iso = lower(tags->'ISO3166-1:alpha2');
  -- generate an array of all official language names
  IF offlangs IS NOT NULL THEN
    FOREACH lang IN ARRAY offlangs
    LOOP
       tag := 'name:' || lang;
       IF tags ? tag THEN
         IF NOT (tags->tag) = ANY(names::text[]) THEN
           names=array_append(names,tags->tag);
         END IF;
       END IF;
    END LOOP;
  END IF;
  IF names IS NULL THEN
    return tags->'name';
  END IF;
  return array_to_string(names,separator);
 END;
$$ LANGUAGE 'plpgsql' STABLE;
