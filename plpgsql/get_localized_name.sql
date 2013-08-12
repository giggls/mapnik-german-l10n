/*

name localization for german mapnik style 

http://wiki.openstreetmap.org/wiki/German_Style

Get the name tag which is the most appropriate one for a german map

This can be used for any language using latin script.

usage examples:
select get_localized_name('Köln',NULL,NULL,'Cologne') as name;
select get_localized_name('เชียงใหม่',NULL,'Chiang Mai',NULL) as name;
select get_localized_name('Москва́',NULL,NULL,NULL) as name;

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

CREATE or REPLACE FUNCTION get_localized_name(name text, local_name text, int_name text, name_en text) RETURNS TEXT AS $$
  BEGIN
    IF (local_name is NULL) THEN
      IF (int_name is NULL) THEN
	IF (name_en is NULL) THEN
          if (name is NULL) THEN
            return NULL;
          END IF;
          if (name = '') THEN
            return '';
          END IF;
	  /* if transliteration is available add here with a latin1 check */
          IF is_latin(name) THEN
            return name;
          ELSE
            return transliterate(name);
          END IF;
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
      return local_name;
    END IF;
  END;
$$ LANGUAGE 'plpgsql';

