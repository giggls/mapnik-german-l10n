/*

name localization for german mapnik style 

http://wiki.openstreetmap.org/wiki/German_Style

Get the name tag which is the most appropriate one for a german map

This can be easily adapted to any other european language by just replacing "de"
with your favourite language code.

usage examples:
select get_germanified_name('Köln',NULL,NULL,'Cologne') as name;
select get_germanified_name('เชียงใหม่',NULL,'Chiang Mai',NULL) as name;

(c) 2013 Sven Geggus <svn-osm@geggus.net> public domain

*/

/* helper function "is_latin" checks if string consists of latin characters only */
CREATE or REPLACE FUNCTION is_latin(text) RETURNS BOOLEAN AS $$
  DECLARE
    i integer;
  BEGIN
    FOR i IN 1..char_length($1) LOOP
      IF (ascii(substr($1, i, 1)) > 591) THEN
        RETURN false;
      END IF;
    END LOOP;
    RETURN true;
  END;
$$ LANGUAGE 'plpgsql';

CREATE or REPLACE FUNCTION get_germanified_name(name text, name_de text, int_name text, name_en text) RETURNS TEXT AS $$
  BEGIN
    IF (name_de is NULL) THEN
      IF (int_name is NULL) THEN
	IF (name_en is NULL) THEN
	  /* if transliteration is available add here with a latin1 check */
	  return name;
	ELSE
	  IF (name_en != name) THEN
	    IF is_latin(name) THEN
	      return name;
	    ELSE
	      return name_en;
	    END IF;
          ELSE
            return name;
          END IF; 
	END IF;        
      ELSE
	IF (int_name != name) THEN
	  IF is_latin(name) THEN
	    return name;
	  ELSE
	   return int_name;
          END IF;
	ELSE
	  return name;
	END IF;
      END IF;
    ELSE
      return name_de;
    END IF;
  END;
$$ LANGUAGE 'plpgsql';

