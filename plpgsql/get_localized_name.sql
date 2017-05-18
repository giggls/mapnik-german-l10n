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
   helper function "osml10n_gen_combined_name"
   Will create a name+local_name pair
   
   In case tags are given the combination night be re-created manually
   from a name:xx tag using the requested separator
   
*/       
CREATE or REPLACE FUNCTION osml10n_gen_combined_name(local_name text, name text, loc_in_brackets boolean, show_brackets boolean DEFAULT true, separator text DEFAULT ' ', tags hstore DEFAULT NULL) RETURNS TEXT AS $combined$
 DECLARE
   nobrackets boolean;
   regex text;
   unacc text;
   unacc_local text;
   unacc2 text;
   tag text;
 BEGIN
  IF (name is NULL) THEN
   return local_name;
  END IF;
  nobrackets=false;
  /* Now we need to do some heuristic to check if the generation of a
     combined name is a good idea.
  
     Currently we do the following:
     If tags is NULL:
     If local_name is part of name as a single word, not just as a substring
     we return name and discard local_name.
     Otherwise we return a combined name with name and local_name
     
     If tags is not NULL:
     If local_name is part of name as a single word, not just as a substring
     we try to extract a second valid name (defined in "name:*" as a single word)
     from "name". If succeeeded we redefine name and also return a combined name.
     
     This is useful in bilingual areas where name usually contains two langages.
     E.g.: name=>"Bolzano - Bozen", target language="de" would be rendered as:
     
     Bozen
     Bolzano
     
     
  */
  unacc = unaccent(name);
  unacc_local = unaccent(local_name);
  if (position(unacc_local in unacc) >0) THEN
    /* the regexp_replace function below is a quotemeta equivalent 
       http://stackoverflow.com/questions/11442090/implementing-quotemeta-q-e-in-tcl/11442113
    */
    regex = '[\s\(\)\-,;:/\[\]](' || regexp_replace(unacc_local, '[][#$^*()+{}\\|.?-]', '\\\&', 'g') ||')[\s\(\)\-,;:/\[\]]';
    -- raise notice 'regex: %',regex;
    IF regexp_matches(concat(' ',unacc,' '),regex) IS NOT NULL THEN
      /* try to create a better string for name */
      IF tags IS NULL THEN
        nobrackets=true;
      ELSE
        FOREACH tag IN ARRAY akeys(tags)
        LOOP
          IF (tag ~ '^name:.+$') THEN
            IF (tags->tag != unacc_local) THEN
              unacc2 = unaccent(tags->tag);
              regex = '[\s\(\)\-,;:/\[\]](' || regexp_replace(unacc2, '[][#$^*()+{}\\|.?-]', '\\\&', 'g') ||')[\s\(\)\-,;:/\[\]]';
              IF regexp_matches(concat(' ',unacc,' '),regex) IS NOT NULL THEN
                -- raise notice 'using % (%) as second name', tags->tag, tag;
                name = tags->tag;
                EXIT;
              ELSE
                nobrackets=true;
              END IF;
            END IF;
          END IF;
        END LOOP;
      END IF;
    END IF;
  END IF;
  
  -- raise notice 'nobrackets: %',nobrackets;
  IF nobrackets THEN    
    return name;                                                       
  ELSE
   IF ( loc_in_brackets ) THEN
     -- explicitely mark the whole string as LTR
     IF ( show_brackets ) THEN
       return chr(8237)||name||separator||'('||local_name||')'||chr(8236);
     ELSE
       return chr(8237)||name||separator||local_name||chr(8236);
     END IF;
   ELSE
     -- explicitely mark the whole string as LTR
     IF ( show_brackets ) THEN
       return chr(8237)||local_name||separator||'('||name||')'||chr(8236);
    ELSE
       return chr(8237)||local_name||separator||name||chr(8236);
    END IF;
   END IF;
  END IF;
 END;
$combined$ LANGUAGE 'plpgsql' IMMUTABLE;


CREATE or REPLACE FUNCTION osml10n_get_placename(name text,
                                                 local_name text,
                                                 int_name text,
                                                 name_en text,
                                                 loc_in_brackets boolean,
                                                 show_brackets boolean DEFAULT false,
                                                 separator text DEFAULT chr(10),                                                                                                                     
                                                 place geometry DEFAULT NULL
                                                 ) RETURNS TEXT AS $$
  BEGIN
    IF (local_name is not NULL) THEN
      return osml10n_gen_combined_name(local_name,name,loc_in_brackets,show_brackets,separator);
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
          return osml10n_gen_combined_name(int_name,name,loc_in_brackets,show_brackets,separator);
        END IF;
      END IF;
      IF (name_en is not NULL) THEN
        return osml10n_gen_combined_name(name_en,name,loc_in_brackets,show_brackets,separator);
      END IF;
      -- transliteration as last resort
      return osml10n_gen_combined_name(osml10n_geo_translit(name,place),name,loc_in_brackets,show_brackets,separator);
    ELSE
      return NULL;
    END IF;
  END;
$$ LANGUAGE 'plpgsql' STABLE;

CREATE or REPLACE FUNCTION osml10n_get_streetname(name text,
                                                  local_name text,
                                                  int_name text,
                                                  name_en text,
                                                  loc_in_brackets boolean,
                                                  show_brackets boolean DEFAULT false,
                                                  separator text DEFAULT ' - ',
                                                  langcode text DEFAULT 'de',
                                                  place geometry DEFAULT NULL) RETURNS TEXT AS $$
  DECLARE
    abbrev text;
  BEGIN
    IF (local_name is not NULL) THEN
      return osml10n_gen_combined_name(osml10n_street_abbrev(local_name,langcode),osml10n_street_abbrev_all(name),loc_in_brackets,show_brackets,separator);
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
          return osml10n_gen_combined_name(osml10n_street_abbrev_en(int_name),osml10n_street_abbrev_non_latin(name),loc_in_brackets,show_brackets,separator);
        END IF;
      END IF;
      IF (name_en is not NULL) THEN
        return osml10n_gen_combined_name(osml10n_street_abbrev_en(name_en),osml10n_street_abbrev_non_latin(name),loc_in_brackets,show_brackets,separator);
      END IF;
      -- transliteration as last resort
      abbrev = osml10n_street_abbrev_non_latin(name);
      return osml10n_gen_combined_name(osml10n_geo_translit(abbrev,place),abbrev,loc_in_brackets,show_brackets,separator);
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


