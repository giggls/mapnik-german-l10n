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
  stmt text;
  func text;
  result text;
 BEGIN
  IF (position('-' in langcode)>0) THEN
    return longname;
  END IF;
  IF (position('_' in langcode)>0) THEN
    return longname;
  END IF;
  func ='osml10n_street_abbrev_'|| langcode;
  stmt = 'select ' || func || '(' || quote_nullable(longname) || ')';
  execute stmt into result;
  return result;
 EXCEPTION
  WHEN undefined_function THEN
   return longname;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT;

/*
   helper function "osml10n_street_abbrev_de"
   replaces some common parts of German street names with their abbr
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_de(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=longname;
  IF (position('traße' in abbrev)>2) THEN
   abbrev=regexp_replace(abbrev,'Straße\M','Str.');
   abbrev=regexp_replace(abbrev,'straße\M','str.');
  END IF;
  IF (position('asse' in abbrev)>2) THEN
   abbrev=regexp_replace(abbrev,'Strasse\M','Str.');
   abbrev=regexp_replace(abbrev,'strasse\M','str.');
   abbrev=regexp_replace(abbrev,'Gasse\M','G.');
   abbrev=regexp_replace(abbrev,'gasse\M','g.');
  END IF;
  IF (position('latz' in abbrev)>2) THEN
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
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT PARALLEL SAFE COST 20;

/*
   helper function "osml10n_street_abbrev_fr"
   replaces some common parts of French street names with their abbreviation
   Main source: https://www.canadapost.ca/tools/pg/manual/PGaddress-f.asp#1460716
*/
CREATE OR REPLACE FUNCTION osml10n_street_abbrev_fr(longname text) RETURNS TEXT AS $$
 DECLARE
  match text[];
 BEGIN
  IF strpos(longname, 'Avenue') > 1 THEN
    /* These are also French names and Avenue is not at the beginning of the Name
      those apear in French speaking parts of canada
      + Normalize ^1ere, ^1re, ^1e to 1re */
    longname = regexp_replace(longname, '^1([eè]?r?)e Avenue\M','1re Av.');
    longname = regexp_replace(longname, '^([0-9]+)e Avenue\M','\1e Av.');
  END IF;

  match = regexp_matches(longname, '^(Avenue|Boulevard|Chemin|Esplanade|Impasse|Passage|Promenade|Route|Ruelle|Sentier)\M');
  IF match IS NOT NULL THEN
    longname = CASE match[1]
      /* We assume, that in French "Avenue" is always at the beginning of the name
          otherwise this is likely English. */
      WHEN 'Avenue' THEN 'Av.'
      WHEN 'Boulevard' THEN 'Bd'
      WHEN 'Chemin' THEN 'Ch.'
      WHEN 'Esplanade' THEN 'Espl.'
      WHEN 'Impasse' THEN 'Imp.'
      WHEN 'Passage' THEN 'Pass.'
      WHEN 'Promenade' THEN 'Prom.'
      WHEN 'Route' THEN 'Rte'
      WHEN 'Ruelle' THEN 'Rle'
      WHEN 'Sentier' THEN 'Sent.'
    END || substr(longname, length(match[1]) + 1);
  END IF;

  RETURN longname;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT PARALLEL SAFE COST 20;

/*
   helper function "osml10n_street_abbrev_es"
   replaces some common parts of Spanish street names with their abbreviation
   currently just a stub :(
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_es(longname text) RETURNS TEXT AS $$
 SELECT longname;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 20;

/*
   helper function "osml10n_street_abbrev_pt"
   replaces some common parts of Portuguese street names with their abbreviation
   currently just a stub :(
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_pt(longname text) RETURNS TEXT AS $$
 SELECT longname;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 20;

/*
   helper function "osml10n_street_abbrev_en"
   replaces some common parts of English street names with their abbreviation
   Most common abbreviations extracted from:
   http://www.ponderweasel.com/whats-the-difference-between-an-ave-rd-st-ln-dr-way-pl-blvd-etc/
*/
CREATE OR REPLACE FUNCTION osml10n_street_abbrev_en(longname text) RETURNS TEXT AS $$
 DECLARE
  match text[];
 BEGIN
  IF strpos(longname, 'Avenue') > 1 THEN
    /* Avenue is a special case because we must try to e xclude french names */
    longname = regexp_replace(longname, '(?<!^([0-9]+([èe]?r)?e )?)Avenue\M','Ave.');
  END IF;
  IF strpos(longname, 'Boulevard') > 1 THEN
    longname = regexp_replace(longname, '(?!^)Boulevard\M','Blvd.');
  END IF;

  match = regexp_matches(longname, '(Crescent|Court|Drive|Lane|Place|Road|Street|Square|Expressway|Freeway|Parkway)\M');
  IF match IS NOT NULL THEN
    longname = replace(longname, match[1], CASE match[1]
      WHEN 'Crescent' THEN 'Cres.'
      WHEN 'Court' THEN 'Ct'
      WHEN 'Drive' THEN 'Dr.'
      WHEN 'Lane' THEN 'Ln.'
      WHEN 'Place' THEN 'Pl.'
      WHEN 'Road' THEN 'Rd.'
      WHEN 'Street' THEN 'St.'
      WHEN 'Square' THEN 'Sq.'

      WHEN 'Expressway' THEN 'Expy'
      WHEN 'Freeway' THEN 'Fwy'
      WHEN 'Parkway' THEN 'Pkwy'
    END);
  END IF;

  match = regexp_matches(longname, '(North|South|West|East|Northwest|Northeast|Southwest|Southeast)\M');
  IF match IS NOT NULL THEN
    longname = replace(longname, match[1], CASE match[1]
      WHEN 'North' THEN 'N'
      WHEN 'South' THEN 'S'
      WHEN 'West' THEN 'W'
      WHEN 'East' THEN 'E'
      WHEN 'Northwest' THEN 'NW'
      WHEN 'Northeast' THEN 'NE'
      WHEN 'Southwest' THEN 'SW'
      WHEN 'Southeast' THEN 'SE'
    END);
  END IF;

  RETURN longname;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT PARALLEL SAFE COST 20;



/*
   helper function "osml10n_street_abbrev_ru"
   replaces улица (ulica) with ул. (ul.)
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_ru(longname text) RETURNS TEXT AS $$
 SELECT replace(replace(replace(replace(replace(replace(replace(replace(
   longname,
   'переулок', 'пер.'),
   'тупик', 'туп.'),
   'улица', 'ул.'),
   'бульвар', 'бул.'),
   'площадь', 'пл.'),
   'проспект', 'просп.'),
   'спуск', 'сп.'),
   'набережная', 'наб.');
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 20;

/*
   helper function "osml10n_street_abbrev_uk"
   replaces ukrainian street suffixes with their abbreviations
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_uk(longname text) RETURNS TEXT AS
$$
 SELECT replace(replace(replace(replace(replace(replace(replace(replace(
   longname,
   'провулок', 'пров.'),
   'тупик', 'туп.'),
   'вулиця', 'вул.'),
   'бульвар', 'бул.'),
   'площа', 'пл.'),
   'проспект', 'просп.'),
   'спуск', 'сп.'),
   'набережна', 'наб.');
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 20;

/*
   helper function "osml10n_street_abbrev_all_latin"
   call all latin osml10n_street_abbrev functions
   These are currently: English, German and French

*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_latin(longname text) RETURNS TEXT AS $$
SELECT
    osml10n_street_abbrev_fr(
            osml10n_street_abbrev_de(
                    osml10n_street_abbrev_en(
                            longname)));
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 20;


/*
   helper function "osml10n_street_abbrev_non_latin"
   call all non latin osml10n_street_abbrev functions
   These are currently: Russian, Ukrainian

*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_non_latin(longname text) RETURNS TEXT AS $$
SELECT
    osml10n_street_abbrev_uk(
            osml10n_street_abbrev_ru(
                    longname));
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 20;


/*
   helper function "osml10n_street_abbrev_all"
   call all osml10n_street_abbrev functions
   These are currently russian, english and german

*/
CREATE OR REPLACE FUNCTION osml10n_street_abbrev_all(longname text) RETURNS TEXT AS $$
SELECT
    CASE WHEN osml10n_contains_cyrillic(longname) THEN
             osml10n_street_abbrev_non_latin(longname)
         ELSE
             osml10n_street_abbrev_latin(longname)
        END;
$$ LANGUAGE SQL IMMUTABLE STRICT PARALLEL SAFE COST 20;
