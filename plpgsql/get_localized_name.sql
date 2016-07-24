/*

renderer independent name localization
used in german mapnik style available at

https://github.com/giggls/openstreetmap-carto-de

Get the name tag which is the most appropriate one for a german map

However, this can be used for any target language using latin script!

This code will also need get_country.sql and geo_transliterate.sql to work properly

osml10n_get_placename(name text, local_name text, int_name text, name_en text, loc_in_brackets boolean, place geometry):
Will try its best to return a usable name pair with name in brackets (or vise versa if loc_in_brackets is set)

osml10n_get_streetname(name text, local_name text, int_name text, name_en text, loc_in_brackets boolean, place geometry)
 same as get_localized_placename, but with some common abbreviations 
 for german street names (Straße->Str.), if name ist longer than 15 characters

osml10n_get_name_without_brackets(name text, local_name text, int_name text, name_en text, place geometry)
 same as get_localized_placename, but with no names in brackets
 
usage examples:

select osml10n_get_placename('Москва́','Moskau',NULL,'Moscow',true) as name;
       ---> "Москва́ (Moskau)"
select osml10n_get_placename('Москва́','Moskau',NULL,'Moscow',false) as name;
       -->  "Moskau (Москва́́́́́́́́́́)"
select osml10n_get_placename('القاهرة','Kairo','Cairo','Cairo',false) as name;
       --> "Kairo"
select osml10n_get_placename('Brixen Bressanone','Brixen',NULL,NULL,false) as name;
       --> "Brixen"
select osml10n_get_streetname('Doktor-No-Straße',NULL,NULL,NULL,false) as name;
       --> "Dr.-No-Str."
select osml10n_get_streetname('Dr. No Street','Professor-Doktor-No-Straße',NULL,NULL,false) as name;
       --> "Prof.-Dr.-No-Str. (Dr. No Street)"
select osml10n_get_name_without_brackets('Dr. No Street','Doktor-No-Straße',NULL,NULL) as name;
       --> "Doktor-No-Straße"       
select osml10n_get_streetname('улица Воздвиженка',NULL,NULL,'Vozdvizhenka Street',true,'de');
       --> "ул. Воздвиженка (Vozdvizhenka St.)"
select osml10n_get_streetname('улица Воздвиженка',NULL,NULL,NULL,true,'de');
       --> "ул. Воздвиженка (ul. Vozdviženka)"

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
   helper function "osml10n_is_allowed_char_range"
   checks if string consists of allowed char_ranges only, These are currently
   
   * latin
   * greek
   * cyrillic
   
*/
CREATE or REPLACE FUNCTION osml10n_is_allowed_char_range(text) RETURNS BOOLEAN AS $$
  DECLARE
    i integer;
  BEGIN
    FOR i IN 1..char_length($1) LOOP
      IF (ascii(substr($1, i, 1)) > 1327) THEN
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
   helper function "osml10n_street_abbrev"
   will call the osml10n_street_abbrev function of the given language if available
   and return the unmodified input otherwise   
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev(longname text, langcode text) RETURNS TEXT AS $$
 DECLARE
  call text;
  result text;
 BEGIN
  call='select osml10n_street_abbrev_' || langcode || '(''' || longname || ''')';
  execute call into result;
  return result;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_all"
   call all osml10n_street_abbrev functions
   These are currently russian, english and german
   
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_all(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=osml10n_street_abbrev_de(longname);
  abbrev=osml10n_street_abbrev_en(abbrev);
  abbrev=osml10n_street_abbrev_ru(abbrev);
  return abbrev;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_all_latin"
   call all latin osml10n_street_abbrev functions
   These are currently: english and german
   
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_all_latin(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=osml10n_street_abbrev_de(longname);
  abbrev=osml10n_street_abbrev_en(abbrev);
  return abbrev;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_non_latin"
   call all non latin osml10n_street_abbrev functions
   These are currently: russian, ukrainian
   
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_non_latin(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=osml10n_street_abbrev_ru(longname);
  abbrev=osml10n_street_abbrev_uk(abbrev);
  return abbrev;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;



/* 
   helper function "osml10n_street_abbrev_de"
   replaces some common parts of german street names with their abbr
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_de(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=longname;
  IF (position('traße' in abbrev)>0) THEN
   abbrev=regexp_replace(abbrev,'Straße\M','Str.');
   abbrev=regexp_replace(abbrev,'straße\M','str.');
  END IF;
  IF (position('asse' in abbrev)>0) THEN
   abbrev=regexp_replace(abbrev,'Strasse\M','Str.');
   abbrev=regexp_replace(abbrev,'strasse\M','str.');
   abbrev=regexp_replace(abbrev,'Gasse\M','G.');
   abbrev=regexp_replace(abbrev,'gasse\M','g.');
  END IF;
  IF (position('latz' in abbrev)>0) THEN
   abbrev=regexp_replace(abbrev,'Platz\M','Pl.');
   abbrev=regexp_replace(abbrev,'platz\M','pl.');
  END IF;
  IF (position('Professor' in abbrev)>0) THEN
   abbrev=replace(abbrev,'Professor ','Prof. ');
   abbrev=replace(abbrev,'Professor-','Prof.-');
  END IF;
  IF (position('Doktor' in abbrev)>0) THEN
   abbrev=replace(abbrev,'Doktor ','Dr. ');
   abbrev=replace(abbrev,'Doktor-','Dr.-');
  END IF;
  IF (position('Bürgermeister' in abbrev)>0) THEN
   abbrev=replace(abbrev,'Bürgermeister ','Bgm. ');
   abbrev=replace(abbrev,'Bürgermeister-','Bgm.-');
  END IF;
  IF (position('Sankt' in abbrev)>0) THEN
   abbrev=replace(abbrev,'Sankt ','St. ');
   abbrev=replace(abbrev,'Sankt-','St.-');
  END IF;
  return abbrev;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_en"
   replaces some common parts of english street names with their abbr
   Most common abbreviations extracted from:
   http://www.ponderweasel.com/whats-the-difference-between-an-ave-rd-st-ln-dr-way-pl-blvd-etc/
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_en(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=longname;
  abbrev=regexp_replace(abbrev,'Boulevard\M','Blvd.');
  abbrev=regexp_replace(abbrev,'Drive\M','Dr.');
  abbrev=regexp_replace(abbrev,'Avenue\M','Ave.');
  abbrev=regexp_replace(abbrev,'Street\M','St.');
  abbrev=regexp_replace(abbrev,'Road\M','Rd.');
  abbrev=regexp_replace(abbrev,'Lane\M','Ln.');
  abbrev=regexp_replace(abbrev,'Place\M','Pl.');
  abbrev=regexp_replace(abbrev,'Square\M','Sq.');
  abbrev=regexp_replace(abbrev,'Crescent\M','Cres.');
  return abbrev;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_ru"
   replaces улица (ulica) with ул. (ul.)
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_ru(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=regexp_replace(longname,'переулок','пер.');
  abbrev=regexp_replace(abbrev,'тупик','туп.');
  abbrev=regexp_replace(abbrev,'улица','ул.');
  abbrev=regexp_replace(abbrev,'бульвар','бул.');
  abbrev=regexp_replace(abbrev,'площадь','пл.');
  abbrev=regexp_replace(abbrev,'проспект','просп.');
  abbrev=regexp_replace(abbrev,'спуск','сп.');
  abbrev=regexp_replace(abbrev,'набережная','наб.');
  return abbrev;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_uk"
   replaces ukrainian street suffixes with their abbreviations
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_uk(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=regexp_replace(longname,'провулок','пров.');
  abbrev=regexp_replace(abbrev,'тупик','туп.');
  abbrev=regexp_replace(abbrev,'вулиця','вул.');
  abbrev=regexp_replace(abbrev,'бульвар','бул.');
  abbrev=regexp_replace(abbrev,'площа','пл.');
  abbrev=regexp_replace(abbrev,'проспект','просп.');
  abbrev=regexp_replace(abbrev,'спуск','сп.');
  abbrev=regexp_replace(abbrev,'набережна','наб.');
  return abbrev;
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
  if osml10n_is_allowed_char_range(name) THEN
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
  ELSE
   return local_name;
  END IF;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;


CREATE or REPLACE FUNCTION osml10n_get_placename(name text, local_name text, int_name text, name_en text, loc_in_brackets boolean, place geometry DEFAULT NULL) RETURNS TEXT AS $$
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
          IF osml10n_is_latin(name) THEN
            return name;
          ELSE /* called if name is not latin and transliteration is needed */
            return osml10n_gen_bracketed_name(osml10n_geo_translit(name,place),name,loc_in_brackets);
          END IF;
	ELSE /* called if name_en != NULL */
	  return osml10n_gen_bracketed_name(name_en,name,loc_in_brackets);
	END IF;        
      ELSE /* called if int_name != NULL */
       return osml10n_gen_bracketed_name(int_name,name,loc_in_brackets);
      END IF;
    ELSE /* called if local_name != NULL */
     return osml10n_gen_bracketed_name(local_name,name,loc_in_brackets);
    END IF;
  END;
$$ LANGUAGE 'plpgsql' STABLE;


CREATE or REPLACE FUNCTION osml10n_get_streetname(name text, local_name text, int_name text, name_en text, loc_in_brackets boolean, langcode text DEFAULT 'de', place geometry DEFAULT NULL) RETURNS TEXT AS $$
  DECLARE
    abbrevname text;
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
          /*
            This might be a target language name thus we call all latin osml10n_street_abbrev
            functions as it seems to be way too expensive to check if the given node is inside
            the country using the target language.
          */
          IF osml10n_is_latin(name) THEN
            abbrevname=osml10n_street_abbrev_all_latin(name);
            return abbrevname;            
          ELSE /* called if name is not latin and transliteration is needed */
            abbrevname=osml10n_street_abbrev_non_latin(name);
            return osml10n_gen_bracketed_name(osml10n_geo_translit(abbrevname,place),abbrevname,loc_in_brackets);
          END IF;
          /*
            int_name is likely and name_en is certainly english
            thus only run osml10n_street_abbrev_en on both
          */
	ELSE /* called if name_en != NULL */
	  return osml10n_gen_bracketed_name(osml10n_street_abbrev_en(name_en),osml10n_street_abbrev_all(name),loc_in_brackets);
	END IF;        
      ELSE /* called if int_name != NULL */
       return osml10n_gen_bracketed_name(osml10n_street_abbrev_en(int_name),osml10n_street_abbrev_all(name),loc_in_brackets);
      END IF;
    ELSE /* called if local_name != NULL */
     return osml10n_gen_bracketed_name(osml10n_street_abbrev(local_name,langcode),osml10n_street_abbrev_all(name),loc_in_brackets);
    END IF;  
  END;
$$ LANGUAGE 'plpgsql' STABLE;


CREATE or REPLACE FUNCTION osml10n_get_name_without_brackets(name text, local_name text, int_name text, name_en text, place geometry DEFAULT NULL) RETURNS TEXT AS $$
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
          IF osml10n_is_latin(name) THEN
            return name;
          ELSE /* called if name is not latin and transliteration is needed */
            return osml10n_geo_translit(name,place);
          END IF;
	ELSE /* called if name_en != NULL */
	  return name_en;
	END IF;        
      ELSE /* called if int_name != NULL */
       return int_name;
      END IF;
    ELSE /* called if local_name != NULL */
     return local_name;
    END IF;
  END;
$$ LANGUAGE 'plpgsql' STABLE;


