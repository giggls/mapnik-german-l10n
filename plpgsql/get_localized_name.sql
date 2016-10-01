/*

renderer independent name localization
used in german mapnik style available at

https://github.com/giggls/openstreetmap-carto-de

(c) 2014-2016 Sven Geggus <svn-osm@geggus.net>, Max Berger <max@dianacht.de>

Licence AGPL http://www.gnu.org/licenses/agpl-3.0.de.html

*/


/* 
   helper function "osml10n_is_latin"
   checks if string consists of latin characters only
*/
CREATE or REPLACE FUNCTION osml10n_is_latin(text) RETURNS BOOLEAN AS $$
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
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_contains_cjk"
  checks if string contains CJK characters
  = 0x4e00-0x9FFF in unicode table
*/
CREATE or REPLACE FUNCTION osml10n_contains_cjk(text) RETURNS BOOLEAN AS $$
  DECLARE
    i integer;
    c integer;
  BEGIN
    FOR i IN 1..char_length($1) LOOP
      c = ascii(substr($1, i, 1));
      IF ((c > 19967) AND (c < 40960)) THEN
        RETURN true;
      END IF;
    END LOOP;
    RETURN false;
  END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_gen_bracketed_name"
   Will create a name (name in brackets) pair       
*/       
CREATE or REPLACE FUNCTION osml10n_gen_bracketed_name(local_name text, name text, loc_in_brackets boolean) RETURNS TEXT AS $$
 BEGIN
  IF (name is NULL) THEN
   return local_name;
  END IF;
  IF ( position(local_name in name)>0 or position('(' in name)>0 or position('(' in local_name)>0 ) THEN    
   IF ( loc_in_brackets ) THEN
    return name;                                                       
   ELSE
    return local_name;
   END IF;
  ELSE
   IF ( loc_in_brackets ) THEN
     return name||' ('||local_name||')';
   ELSE
     return local_name||' ('||name||')';
   END IF;
  END IF;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;


CREATE or REPLACE FUNCTION osml10n_get_placename(name text, local_name text, int_name text, name_en text, loc_in_brackets boolean, place geometry DEFAULT NULL) RETURNS TEXT AS $$
  BEGIN
    IF (local_name is not NULL) THEN
      return osml10n_gen_bracketed_name(local_name,name,loc_in_brackets);
    END IF;
    IF (name is not NULL) THEN
      if (name = '') THEN
        return '';
      END IF;
      IF osml10n_is_latin(name) THEN
        return name;
      END IF;
      -- at this stage name is not latin so we need to have a look at alternatives
      -- these are currently international and english names
      IF (int_name is not NULL) THEN
        if osml10n_is_latin(int_name) THEN
          return osml10n_gen_bracketed_name(int_name,name,loc_in_brackets);
        END IF;
      END IF;
      IF (name_en is not NULL) THEN
        return osml10n_gen_bracketed_name(name_en,name,loc_in_brackets);
      END IF;
      -- transliteration as last resort
      return osml10n_gen_bracketed_name(osml10n_geo_translit(name,place),name,loc_in_brackets);
    ELSE
      return NULL;
    END IF;
  END;
$$ LANGUAGE 'plpgsql' STABLE;

CREATE or REPLACE FUNCTION osml10n_get_streetname(name text, local_name text, int_name text, name_en text, loc_in_brackets boolean, langcode text DEFAULT 'de', place geometry DEFAULT NULL) RETURNS TEXT AS $$
  DECLARE
    abbrev text;
  BEGIN
    IF (local_name is not NULL) THEN
      return osml10n_gen_bracketed_name(osml10n_street_abbrev(local_name,langcode),osml10n_street_abbrev_all(name),loc_in_brackets);
    END IF;
    IF (name is not NULL) THEN
      if (name = '') THEN
        return '';
      END IF;
      IF osml10n_is_latin(name) THEN
        return osml10n_street_abbrev_all_latin(name);
      END IF;
      -- at this stage name is not latin so we need to have a look at alternatives
      -- these are currently international and english names
      IF (int_name is not NULL) THEN
        if osml10n_is_latin(int_name) THEN
          return osml10n_gen_bracketed_name(osml10n_street_abbrev_en(int_name),osml10n_street_abbrev_non_latin(name),loc_in_brackets);
        END IF;
      END IF;
      IF (name_en is not NULL) THEN
        return osml10n_gen_bracketed_name(osml10n_street_abbrev_en(name_en),osml10n_street_abbrev_non_latin(name),loc_in_brackets);
      END IF;
      -- transliteration as last resort
      abbrev = osml10n_street_abbrev_non_latin(name);
      return osml10n_gen_bracketed_name(osml10n_geo_translit(abbrev,place),abbrev,loc_in_brackets);
    ELSE
      return NULL;
    END IF;
  END;
$$ LANGUAGE 'plpgsql' STABLE;

CREATE or REPLACE FUNCTION osml10n_get_name_without_brackets(name text, local_name text, int_name text, name_en text, place geometry DEFAULT NULL) RETURNS TEXT AS $$
  BEGIN
    IF (local_name is not NULL) THEN
      return local_name;
    END IF;
    IF (name is not NULL) THEN
      if (name = '') THEN
        return '';
      END IF;
      IF osml10n_is_latin(name) THEN
        return name;
      END IF;
      -- at this stage name is not latin so we need to have a look at alternatives
      -- these are currently international and english names
      IF (int_name is not NULL) THEN
        if osml10n_is_latin(int_name) THEN
          return int_name;
        END IF;
      END IF;
      IF (name_en is not NULL) THEN
        return name_en;
      END IF;
      -- transliteration as last resort
      return osml10n_geo_translit(name,place);
    ELSE
      return NULL;
    END IF;
  END;
$$ LANGUAGE 'plpgsql' STABLE;


