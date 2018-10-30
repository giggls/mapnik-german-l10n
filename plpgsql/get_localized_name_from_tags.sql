/*
renderer independent name localization
used in german mapnik style available at

https://github.com/giggls/openstreetmap-carto-de

(c) 2016-2018 Sven Geggus <svn-osm@geggus.net>

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
   
   In case use_tags is true the combination might be re-created manually
   from a name:xx tag using the requested separator instad of name
   using a somewhat heuristic algorithm (see below)
   
   
*/       
CREATE or REPLACE FUNCTION osml10n_gen_combined_name(local_name text,
                                                     name text,
                                                     tags hstore,
                                                     loc_in_brackets boolean,
                                                     show_brackets boolean DEFAULT true,
                                                     separator text DEFAULT ' ',
                                                     is_street boolean DEFAULT false,
                                                     use_tags boolean DEFAULT false,
                                                     non_latin boolean DEFAULT false) RETURNS TEXT AS $combined$
 DECLARE
   nobrackets boolean;
   found boolean;
   regex text;
   unacc text;
   unacc_local text;
   unacc_tag text;
   tag text;
   langcode text;
   n text;
   ln text;
   pos int;
 BEGIN
  IF NOT tags ? 'name' THEN
    IF is_street THEN
      langcode=substring(local_name from position(':' in local_name)+1 for char_length(local_name));
      return(osml10n_street_abbrev(tags->name,langcode));
    ELSE
      return(tags->name);
    END IF;
  END IF;
  nobrackets=false;
  /* Now we need to do some heuristic to check if the generation of a
     combined name is a good idea.
  
     Currently we do the following:
     If use_tags is false:
     If local_name is part of name as a single word, not just as a substring
     we return name and discard local_name.
     Otherwise we return a combined name with name and local_name
     
     If use_tags is true:
     If local_name is part of name as a single word, not just as a substring
     we try to extract a second valid name (defined in "name:*" as a single word)
     from "name". If succeeeded we redefine name and also return a combined name.
     
     This is useful in bilingual areas where name usually contains two langages.
     E.g.: name=>"Bolzano - Bozen", target language="de" would be rendered as:
     
     Bozen
     Bolzano
     
     
  */
  unacc = unaccent(tags->name);
  unacc_local = unaccent(tags->local_name);
  found = false;
  pos=position(unacc_local in unacc);
  if (pos >0) THEN
    /* the regexp_replace function below is a quotemeta equivalent 
       http://stackoverflow.com/questions/11442090/implementing-quotemeta-q-e-in-tcl/11442113
    */
    regex = '[\s\(\)\-,;:/\[\]](' || regexp_replace(unacc_local, '[][#$^*()+{}\\|.?-]', '\\\&', 'g') ||')[\s\(\)\-,;:/\[\]]';
    -- raise notice 'regex: %',regex;
    IF regexp_matches(concat(' ',unacc,' '),regex) IS NOT NULL THEN
      /* try to create a better string for combined name than plain name */
      /* do these complex checks only in case unaccented name != unaccented local_name */
      IF (char_length(unacc_local) = char_length(unacc)) THEN
        IF is_street THEN
          langcode=substring(local_name from position(':' in local_name)+1 for char_length(local_name));
          return(osml10n_street_abbrev(tags->name,langcode));
        ELSE
          return(tags->name);
        END IF;
      END IF;
      IF tags IS NULL THEN
        nobrackets=true;
      ELSE
        FOREACH tag IN ARRAY akeys(tags)
        LOOP
          IF (tag ~ '^name:.+$') THEN
            unacc_tag = unaccent(tags->tag);
            IF (unacc_tag != unacc_local) THEN
              regex = '[\s\(\)\-,;:/\[\]](' || regexp_replace(unacc_tag, '[][#$^*()+{}\\|.?-]', '\\\&', 'g') ||')[\s\(\)\-,;:/\[\]]';
              IF regexp_matches(concat(' ',unacc,' '),regex) IS NOT NULL THEN
                /* As this regex is also true for 1:1 match we need to ignore this special case */
                if ('name' != tag) THEN
                  -- raise notice 'using % (%) as second name', tags->tag, tag;
                  /* we found a 'second' name */
                  /* While a request might want to prefer printing this
                     second name first anyway, to prefer on the ground
                     language over l10n we pretend to know better in one 
                     special case:
                     
                     if the name in our target language is the first one in
                     the generic name tag we will likely also want to print
                     it first in l10n output.
                     
                     This will make a lot of sense in bilingual areas where
                     mappers usually use the convention of putting the more
                     important language first in bilingual generic name tag.
                     
                     So just remove the "loc_in_brackets = false" assignment
                     if you want to get rid of this fuzzy behaviour!
                     
                     Probably it might be a good idea to add an additional
                     strict option to disable this behaviour.
                  */
                  if (pos = 1) THEN
                    IF regexp_matches(substring(unacc,length(unacc_local)+1,1),'[\s\(\)\-,;:/\[\]]') IS NOT NULL THEN
                      raise notice 'swapping primary/second name';
                      loc_in_brackets = false;
                    END IF;
                  END IF;
                  name = tag;
                  nobrackets=false;
                  found=true;
                  langcode=substring(name from position(':' in name)+1 for char_length(name));
                  EXIT;
                ELSE
                  nobrackets=true;
                END IF;
              ELSE
                nobrackets=true;
              END IF;
            END IF;
          END IF;
        END LOOP;
        /* consider other names than local_name crap in case we did not find any */
        IF not found THEN
          IF is_street THEN
            langcode=substring(local_name from position(':' in local_name)+1 for char_length(local_name));
            return(osml10n_street_abbrev(tags->local_name,langcode));
          ELSE
            return(tags->local_name);
          END IF;
        END IF;
      END IF;
    END IF;
  END IF;
  
  -- raise notice 'nobrackets: %',nobrackets;
  IF nobrackets THEN
    IF is_street THEN
      return(osml10n_street_abbrev_all(tags->name));
    ELSE
      return(tags->name);
    END IF;
  ELSE
   IF is_street THEN
     IF (position(':' in local_name) >0) THEN
       langcode=substring(local_name from position(':' in local_name)+1 for char_length(local_name));
       ln=osml10n_street_abbrev(tags->local_name,langcode);
     ELSE
       -- int_name case, we assume that this is in latin script
       ln=osml10n_street_abbrev_latin(tags->local_name);
     END IF;
     IF (position(':' in name) >0) THEN
       langcode=substring(name from position(':' in name)+1 for char_length(name));
       n=osml10n_street_abbrev(tags->name,langcode);
     ELSE
       if non_latin THEN
         n=osml10n_street_abbrev_non_latin(tags->name);
       -- only non-latin case is certain
       ELSE
         n=osml10n_street_abbrev_all(tags->name);
       END IF;
     END IF;
   ELSE
     n=tags->name;
     ln=tags->local_name;
   END IF;
   IF ( loc_in_brackets ) THEN
     -- explicitely mark the whole string as LTR
     IF ( show_brackets ) THEN
       return chr(8234)||n||separator||'('||ln||')'||chr(8236);
     ELSE
       return chr(8234)||n||separator||ln||chr(8236);
     END IF;
   ELSE
     -- explicitely mark the whole string as LTR
     IF ( show_brackets ) THEN
       return chr(8234)||ln||separator||'('||n||')'||chr(8236);
    ELSE
       return chr(8234)||ln||separator||n||chr(8236);
    END IF;
   END IF;
  END IF;
 END;
$combined$ LANGUAGE 'plpgsql' IMMUTABLE;


/*
Get name by looking at various name tags or transliteration as a last resort:

1. name:<targetlang>
2. name (if latin)
3. int_name (if latin)
5. name:en (if not targetlang)
5. name:fr (if not targetlang)
6. name:es (if not targetlang)
7: name:pt (if not targetlang)
8. name:de (if not targetlang)
9. Any tag of the form name:<targetlang>_rm or name:<targetlang>-Latn

This scheme is used in functions:
osml10n_get_name_from_tags and osml10n_get_name_without_brackets_from_tags

*/
CREATE or REPLACE FUNCTION osml10n_get_name_from_tags(tags hstore, 
                                                      loc_in_brackets boolean,
                                                      is_street boolean DEFAULT false,
                                                      show_brackets boolean DEFAULT false,
                                                      separator text DEFAULT chr(10),
                                                      targetlang text DEFAULT 'de',
                                                      place geometry DEFAULT NULL) RETURNS TEXT AS $$
 DECLARE
  -- 5 most commonly spoken languages using latin script (hopefully)   
  latin_langs text[] := '{"en","fr","es","pt","de"}';
  target_tag text;
  lang text;
  tag text;
 BEGIN
   target_tag := 'name:' || targetlang;
   IF tags ? target_tag THEN
     return osml10n_gen_combined_name(target_tag,'name',tags,loc_in_brackets,show_brackets,separator,is_street,true);
   END IF;
   IF tags ? 'name' THEN
     if (tags->'name' = '') THEN
       return '';
     END IF;
     IF osml10n_is_latin(tags->'name') THEN
       IF is_street THEN
         return(osml10n_street_abbrev_all(tags->'name'));
       ELSE
         return tags->'name';
       END IF;
     END IF;
     -- at this stage name is not latin so we need to have a look at alternatives
     -- these are currently int_name, common latin scripts and romanized version of the name
     IF tags ? 'int_name' THEN
       if osml10n_is_latin(tags->'int_name') THEN
         return osml10n_gen_combined_name('int_name','name',tags,loc_in_brackets,show_brackets,separator,is_street,false,true);
       END IF;
     END IF;
     
     -- if any latin language tag is available use it
     FOREACH lang IN ARRAY latin_langs
     LOOP
       -- we already checked for targetlang
       IF lang = targetlang THEN
         continue;
       END IF;
       target_tag := 'name:' || lang;
       if tags ? target_tag THEN
         -- raise notice 'found roman language tag %', target_tag;
         return osml10n_gen_combined_name(target_tag,'name',tags,loc_in_brackets,show_brackets,separator,is_street,true,true);
       END IF;
     END LOOP;
     -- try to find a romanized version of the name
     -- this usually looks like name:ja_rm or  name:ko-Latn
     -- Just use the first tag of this kind found, because
     -- having more than one of them does not make sense
     FOREACH tag IN ARRAY akeys(tags)
     LOOP
       IF ((tag ~ '^name:.+_rm$') or (tag ~ '^name:.+-Latn$')) THEN
         -- raise notice 'found romanization name tag %', tag;
         return osml10n_gen_combined_name(tag,'name',tags,loc_in_brackets,show_brackets,separator,is_street,true,true);
       END IF;
     END LOOP;
     IF is_street THEN
       tags := tags || hstore('name:Latn',osml10n_geo_translit(osml10n_street_abbrev_non_latin(tags->'name'),place));
     ELSE
       tags := tags || hstore('name:Latn',osml10n_geo_translit(tags->'name',place));
     END IF;
     return osml10n_gen_combined_name('name:Latn','name',tags,loc_in_brackets,show_brackets,separator,is_street,false,true);
   ELSE
     return NULL;
   END IF;
 END;
$$ LANGUAGE 'plpgsql' STABLE;

CREATE or REPLACE FUNCTION osml10n_get_name_without_brackets_from_tags(tags hstore,
                                                                       targetlang text DEFAULT 'de',
                                                                       place geometry DEFAULT NULL,
                                                                       name text DEFAULT NULL) RETURNS TEXT AS $$
 DECLARE
  -- 5 most commonly spoken languages using latin script (hopefully)   
  latin_langs text[] := '{"en","fr","es","pt","de"}';
  target_tag text;
  lang text;
  tag text;
 BEGIN
   IF (name IS NOT NULL) THEN
     tags := tags || hstore('name',name);
   END IF;
   target_tag := 'name:' || targetlang;
   IF tags ? target_tag THEN
     return tags->target_tag;
   END IF;
   IF tags ? 'name' THEN
     if (tags->'name' = '') THEN
       return '';
     END IF;
     IF osml10n_is_latin(tags->'name') THEN
       return tags->'name';
     END IF;
     -- at this stage name is not latin so we need to have a look at alternatives
     -- these are currently int_name, common latin scripts and romanized version of the name
     IF tags ? 'int_name' THEN
       IF osml10n_is_latin(tags->'int_name') THEN
         return tags->'int_name';
       END IF;
     END IF;
     
     -- if any latin language tag is available use it
     FOREACH lang IN ARRAY latin_langs
     LOOP
       -- we already checked for targetlang
       IF lang = targetlang THEN
         continue;
       END IF;
       target_tag := 'name:' || lang;
       if tags ? target_tag THEN
         -- raise notice 'found roman language tag %', target_tag;
         return tags->target_tag;
       END IF;
     END LOOP;
     -- try to find a romanized version of the name
     -- this usually looks like name:ja_rm or  name:ko-Latn
     -- Just use the first tag of this kind found, because
     -- having more than one of them does not make sense
     FOREACH tag IN ARRAY akeys(tags)
     LOOP
       IF ((tag ~ '^name:.+_rm$') or (tag ~ '^name:.+-Latn$')) THEN
         -- raise notice 'found romanization name tag %', tag;
         return tags->tag;
       END IF;
     END LOOP;
     -- raise notice 'last resort: doing transliteration';
     return osml10n_geo_translit(tags->'name',place);      
   ELSE
     return NULL;
   END IF;
 END;
$$ LANGUAGE 'plpgsql' STABLE;

/*

"exported functions"

*/
CREATE or REPLACE FUNCTION osml10n_get_placename_from_tags(tags hstore, 
                                                           loc_in_brackets boolean,
                                                           show_brackets boolean DEFAULT false,
                                                           separator text DEFAULT chr(10),
                                                           targetlang text DEFAULT 'de',
                                                           place geometry DEFAULT NULL,
                                                           name text DEFAULT NULL) RETURNS TEXT AS $$
 BEGIN
   -- workaround for openstreetmap carto database layout where name uses its own database column
   IF (name IS NOT NULL) THEN
     tags := tags || hstore('name',name);
   END IF;

   return(osml10n_get_name_from_tags(tags,loc_in_brackets,false,show_brackets,separator,targetlang,place));
 END;
$$ LANGUAGE 'plpgsql' STABLE;


CREATE or REPLACE FUNCTION osml10n_get_streetname_from_tags(tags hstore, 
                                                           loc_in_brackets boolean,
                                                           show_brackets boolean DEFAULT false,
                                                           separator text DEFAULT ' - ',
                                                           targetlang text DEFAULT 'de',
                                                           place geometry DEFAULT NULL,
                                                           name text DEFAULT NULL) RETURNS TEXT AS $$
 BEGIN
   -- workaround for openstreetmap carto database layout where name uses its own database column
   IF (name IS NOT NULL) THEN
     tags := tags || hstore('name',name);
   END IF;
   return(osml10n_get_name_from_tags(tags,loc_in_brackets,true,show_brackets,separator,targetlang,place));
 END;
$$ LANGUAGE 'plpgsql' STABLE;
