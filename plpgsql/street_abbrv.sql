/*

renderer independent name localization
used in german mapnik style available at

https://github.com/giggls/openstreetmap-carto-de

(c) 2014-2016 Sven Geggus <svn-osm@geggus.net>

Licence AGPL http://www.gnu.org/licenses/agpl-3.0.de.html

Street abbreviation functions

*/

/* 
   helper function "osml10n_street_abbrev"
   will call the osml10n_street_abbrev function of the given language if available
   and return the unmodified input otherwise   
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev(longname text, langcode text) RETURNS TEXT AS $$
 DECLARE
  call text;
  func text;
  result text;
 BEGIN
  func ='osml10n_street_abbrev_'|| langcode;
  call = 'select ' || func || '(' || quote_nullable(longname) || ')';
  execute call into result;
  return result;
 EXCEPTION
  WHEN undefined_function THEN
   return longname;
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
  abbrev=osml10n_street_abbrev_uk(abbrev);
  return abbrev;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_all_latin"
   call all latin osml10n_street_abbrev functions
   These are currently: english and german
   
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_latin(longname text) RETURNS TEXT AS $$
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
   helper function "osml10n_street_abbrev_fr"
   replaces some common parts of french street names with their abbreviation
   currently just a stub :(
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_fr(longname text) RETURNS TEXT AS $$
 BEGIN
  return longname;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_es"
   replaces some common parts of spanish street names with their abbreviation
   currently just a stub :(
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_es(longname text) RETURNS TEXT AS $$
 BEGIN
  return longname;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_pt"
   replaces some common parts of portuguese street names with their abbreviation
   currently just a stub :(
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_pt(longname text) RETURNS TEXT AS $$
 BEGIN
  return longname;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_en"
   replaces some common parts of english street names with their abbreviation
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
