/*
renderer independent name localization
used in german mapnik style available at

https://github.com/giggls/openstreetmap-carto-de

(c) 2016-2017 Sven Geggus <svn-osm@geggus.net>

Licence AGPL http://www.gnu.org/licenses/agpl-3.0.de.html
*/

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
9. Any tag of the form name:<targetlang>_rm

This scheme is used in all 3 functions:
osml10n_get_placename_from_tags
osml10n_get_streetname_from_tags
osml10n_get_name_without_brackets_from_tags

*/
CREATE or REPLACE FUNCTION osml10n_get_placename_from_tags(tags hstore, 
                                                           loc_in_brackets boolean,
                                                           show_brackets boolean DEFAULT false,
                                                           separator text DEFAULT chr(10),
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
     return osml10n_gen_combined_name(tags->target_tag,tags->'name',loc_in_brackets,show_brackets,separator,tags);
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
       if osml10n_is_latin(tags->'int_name') THEN
         return osml10n_gen_combined_name(tags->'int_name',tags->'name',loc_in_brackets,show_brackets,separator);
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
         return osml10n_gen_combined_name(tags->target_tag,tags->'name',loc_in_brackets,show_brackets,separator);
       END IF;
     END LOOP;
     -- try to find a romanized version of the name
     -- this usually looks like name:ja_rm or name:kr_rm
     -- thus a suitable regex would be name:.+_rm
     -- Just use the first tag of this kind found, because
     -- having more than one of them does not make sense
     FOREACH tag IN ARRAY akeys(tags)
     LOOP
       IF (tag ~ '^name:.+_rm$') THEN
         -- raise notice 'found romanization name tag %', tag;
         return osml10n_gen_combined_name(tags->tag,tags->'name',loc_in_brackets,show_brackets,separator,tags);
       END IF;
     END LOOP;
     -- raise notice 'last resort: doing transliteration';
     return osml10n_gen_combined_name(osml10n_geo_translit(tags->'name',place),tags->'name',loc_in_brackets,false,separator);
   ELSE
     return NULL;
   END IF;
 END;
$$ LANGUAGE 'plpgsql' STABLE;

/*

Same as osml10n_get_placename_from_tags but with streetname abbreviations

*/
CREATE or REPLACE FUNCTION osml10n_get_streetname_from_tags(tags hstore,
                                                            loc_in_brackets boolean,
                                                            show_brackets boolean DEFAULT false,
                                                            separator text DEFAULT ' - ',
                                                            targetlang text DEFAULT 'de',
                                                            place geometry DEFAULT NULL,
                                                            name text DEFAULT NULL) RETURNS TEXT AS $$
 DECLARE
  -- 5 most commonly spoken languages using latin script (hopefully)   
  latin_langs text[] := '{"en","fr","es","pt","de"}';
  target_tag text;
  lang text;
  tag text;
  abbrev text;
 BEGIN
   IF (name IS NOT NULL) THEN
     tags := tags || hstore('name',name);
   END IF;
   target_tag := 'name:' || targetlang;
   IF tags ? target_tag THEN
     return osml10n_gen_combined_name(osml10n_street_abbrev(tags->target_tag,targetlang),
                                       osml10n_street_abbrev_all(tags->'name'),loc_in_brackets,show_brackets,separator);
   END IF;
   IF tags ? 'name' THEN
     if (tags->'name' = '') THEN
       return '';
     END IF;
     IF osml10n_is_latin(tags->'name') THEN
       return osml10n_street_abbrev_all_latin(tags->'name');
     END IF;
     -- at this stage name is not latin so we need to have a look at alternatives
     -- these are currently int_name, common latin scripts and romanized version of the name
     IF tags ? 'int_name' THEN
       if osml10n_is_latin(tags->'int_name') THEN
         return osml10n_gen_combined_name(osml10n_street_abbrev_en(tags->'int_name'),
                                           osml10n_street_abbrev_all(tags->'name'),loc_in_brackets,show_brackets,separator);
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
         return osml10n_gen_combined_name(osml10n_street_abbrev(tags->target_tag,lang),
                                           osml10n_street_abbrev_all(tags->'name'),loc_in_brackets,show_brackets,separator);
       END IF;
     END LOOP;
     -- try to find a romanized version of the name
     -- this usually looks like name:ja_rm or name:kr_rm
     -- thus a suitable regex would be name:.+_rm
     -- Just use the first tag of this kind found, because
     -- having more than one of them does not make sense
     FOREACH tag IN ARRAY akeys(tags)
     LOOP
       IF (tag ~ '^name:.+_rm$') THEN
         -- raise notice 'found romanization name tag %', tag;
         return osml10n_gen_combined_name(osml10n_street_abbrev_all_latin(tags->tag),
                                           osml10n_street_abbrev_non_latin(tags->'name'),loc_in_brackets,show_brackets,separator,tags);
       END IF;
     END LOOP;
     -- raise notice 'last resort: doing transliteration';
     abbrev = osml10n_street_abbrev_non_latin(tags->'name');
     return osml10n_gen_combined_name(osml10n_geo_translit(abbrev,place),abbrev,loc_in_brackets,show_brackets,separator);
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
     -- this usually looks like name:ja_rm or name:kr_rm
     -- thus a suitable regex would be name:.+_rm
     -- Just use the first tag of this kind found, because
     -- having more than one of them does not make sense
     FOREACH tag IN ARRAY akeys(tags)
     LOOP
       IF (tag ~ '^name:.+_rm$') THEN
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
