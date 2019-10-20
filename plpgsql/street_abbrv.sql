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
  IF (position('-' in langcode)>0) THEN
    return longname;
  END IF;
  IF (position('_' in langcode)>0) THEN
    return longname;
  END IF;  
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
  abbrev=osml10n_street_abbrev_en(longname);
  abbrev=osml10n_street_abbrev_de(abbrev);
  abbrev=osml10n_street_abbrev_fr(abbrev);
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
  abbrev=osml10n_street_abbrev_en(abbrev);
  abbrev=osml10n_street_abbrev_de(longname);
  abbrev=osml10n_street_abbrev_fr(abbrev);
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
$$ LANGUAGE 'plpgsql' IMMUTABLE;

/* 
   helper function "osml10n_street_abbrev_fr"
   replaces some common parts of french street names with their abbreviation
   Main source: https://www.canadapost.ca/tools/pg/manual/PGaddress-f.asp#1460716
*/
CREATE or REPLACE FUNCTION osml10n_street_abbrev_fr(longname text) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
  abbrev=longname;
  abbrev=regexp_replace(abbrev,'^Avenue\M','Av.');
  abbrev=regexp_replace(abbrev,'^Boulevard\M','Bd');
  abbrev=regexp_replace(abbrev,'^Chemin\M','Ch.');
  abbrev=regexp_replace(abbrev,'^Esplanade\M','Espl.');
  abbrev=regexp_replace(abbrev,'^Impasse\M','Imp.');
  abbrev=regexp_replace(abbrev,'^Passage\M','Pass.');
  abbrev=regexp_replace(abbrev,'^Promenade\M','Prom.');
  abbrev=regexp_replace(abbrev,'^Route\M','Rte');
  abbrev=regexp_replace(abbrev,'^Ruelle\M','Rle');
  abbrev=regexp_replace(abbrev,'^Sentier\M','Sent.');
  return abbrev;
 END;
$$ LANGUAGE 'plpgsql' IMMUTABLE;

--
-- Name: fr_abbrev(text); Type: FUNCTION; Schema: public; Owner: postgres
--
CREATE OR REPLACE FUNCTION fr_abbrev(longtext) RETURNS TEXT AS $$
 DECLARE
  abbrev text;
 BEGIN
    abbrev = longtext;
    abbrev = replace($abbrev,'lémentaire ','lem. ');
    abbrev = replace($abbrev, 'econdaire ','econd. ');
    abbrev = replace($abbrev, 'rimaire ','rim. ');
    abbrev = replace($abbrev, 'aternelle ','at. ');
    abbrev = replace($abbrev, 'ommerciale ','omm. ');
    abbrev = replace($abbrev, 'Direction ','Dir. ');
    abbrev = replace($abbrev, 'Chapelle ','Chap. ');
    abbrev = replace($abbrev, 'Cathédrale ','Cath. ');
    abbrev = replace($abbrev, ' Notre-Dame ',' N.D. ');

    abbrev = replace($abbrev, 'Avenue ','Av. ');
    abbrev = replace($abbrev, 'Boulevard ','Bd. ');
    abbrev = replace($abbrev, 'Esplanade ','Espl. ');
    abbrev = replace($abbrev, 'Faubourg ','Fbg. ');
    abbrev = replace($abbrev, 'Passage ','Pass. ');
    abbrev = replace($abbrev, 'Place ','Pl. ');
    abbrev = replace($abbrev, 'Promenade ','Prom. ');
    abbrev = replace($abbrev, 'Impasse ','Imp. ');

    abbrev = replace($abbrev, 'Square ','Sq. ');

    abbrev = replace($abbrev, 'Centre Commercial ','CCial. ');
    abbrev = replace($abbrev, 'Immeuble ','Imm. ');
    abbrev = replace($abbrev, 'Lotissement ','Lot. ');
    abbrev = replace($abbrev, 'Résidence ','Rés. ');
    abbrev = replace($abbrev, 'Zone Industrielle ','ZI. ');
    abbrev = replace($abbrev, 'Adjudant ','Adj. ');
    abbrev = replace($abbrev, 'Agricole ','Agric. ');
    abbrev = replace($abbrev, 'Arrondissement','Arrond.');
    abbrev = replace($abbrev, 'Aspirant ','Asp. ');
    abbrev = replace($abbrev, 'Colonel ','Col. ');
    abbrev = replace($abbrev, 'Commandant ','Cdt. ');
    abbrev = replace($abbrev, 'Commercial ','Cial. ');
    abbrev = replace($abbrev, 'Coopérative ','Coop. ');
    abbrev = replace($abbrev, 'Division ','Div. ');
    abbrev = replace($abbrev, 'Docteur ','Dr. ');
    abbrev = replace($abbrev, 'Général ','Gén. ');
    abbrev = replace($abbrev, 'Institut ','Inst. ');
    abbrev = replace($abbrev, 'Faculté ','Fac. ');
    abbrev = replace($abbrev, 'Laboratoire ','Labo. ');
    abbrev = replace($abbrev, 'Lieutenant ','Lt. ');
    abbrev = replace($abbrev, 'Maréchal ','Mal. ');
    abbrev = replace($abbrev, 'Ministère ','Min. ');
    abbrev = replace($abbrev, 'Monseigneur ','Mgr. ');
    abbrev = replace($abbrev, 'Médiathèque ','Médiat. ');
    abbrev = replace($abbrev, 'Bibliothèque ','Bibl. ');
    abbrev = replace($abbrev, 'Tribunal ','Trib. ');
    abbrev = replace($abbrev, 'Observatoire ','Obs. ');
    abbrev = replace($abbrev, 'Périphérique ','Périph. ');
    abbrev = replace($abbrev, 'Préfecture ','Préf. ');
    abbrev = replace($abbrev, 'Président ','Pdt. ');
    abbrev = replace($abbrev, 'Régiment ','Rgt. ');
    abbrev = replace($abbrev, 'Saint-','Sᵗ-');
    abbrev = replace($abbrev, 'Sainte-','Sᵗᵉ-');
    abbrev = replace($abbrev, 'Sergent ','Sgt. ');
    abbrev = replace($abbrev, 'Université ','Univ. ');

    abbrev = regexp_replace($abbrev, 'Communauté d.[Aa]gglomération','Comm. d''agglo. ');
    abbrev = regexp_replace($abbrev, 'Communauté [Uu]rbaine ','Comm. urb. ');
    abbrev = regexp_replace($abbrev, 'Communauté de [Cc]ommunes ','Comm. comm. ');
    abbrev = regexp_replace($abbrev, 'Syndicat d.[Aa]gglomération ','Synd. d''agglo. ');
    abbrev = regexp_replace($abbrev, '^Chemin ','Ch. ');
    abbrev = regexp_replace($abbrev, '^Institut ','Inst. ');
    abbrev = regexp_replace($abbrev, 'Zone d.[Aa]ctivité.? [Éeée]conommique.? ','Z.A.E. ');
    abbrev = regexp_replace($abbrev, 'Zone d.[Aa]ctivité.? ','Z.A. ');
    abbrev = regexp_replace($abbrev, 'Zone [Aa]rtisanale ','Zone Art. ');
    abbrev = regexp_replace($abbrev, 'Zone [Ii]ndustrielle ','Z.I. ');
    abbrev = regexp_replace($abbrev, ' [Pp]ubli(c|que) ',' Publ. ');
    abbrev = regexp_replace($abbrev, ' [Pp]rofessionnel(|le) ',' Prof. ');
    abbrev = regexp_replace($abbrev, ' [Tt]echnologique ',' Techno. ');
    abbrev = regexp_replace($abbrev, ' [Pp]olyvalent ',' Polyv. ');
    abbrev = regexp_replace($abbrev, '[EÉeé]tablissement(|s) ','Éts. ');
    abbrev = regexp_replace($abbrev, ' [Mm]unicipal(|e) ',' Munic. ');
    abbrev = regexp_replace($abbrev, ' [Dd]épartemental(|e) ',' Départ. ');
    abbrev = regexp_replace($abbrev, ' [Ii]ntercommunal(|le) ',' Interco. ');
    abbrev = regexp_replace($abbrev, ' [Rr]égional(|e) ',' Région. ');
    abbrev = regexp_replace($abbrev, ' [Ii]nterdépartemental(|e) ',' Interdép. ');
    abbrev = regexp_replace($abbrev, ' [Hh]ospitali(er|ère) ',' Hospit. ');
    abbrev = regexp_replace($abbrev, ' [EÉeé]lectrique ',' Élect. ');
    abbrev = regexp_replace($abbrev, ' [Ss]upérieur(|e) ',' Sup. ');
    abbrev = regexp_replace($abbrev, '^[Bb][aâ]timent ','Bât. ');
    abbrev = regexp_replace($abbrev, '[Aa]éronautique ','Aéron. ');

    return abbrev;
    
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
  abbrev=regexp_replace(abbrev,'(?!^)Avenue\M','Ave.');
  abbrev=regexp_replace(abbrev,'(?!^)Boulevard\M','Blvd.');
  abbrev=regexp_replace(abbrev,'Crescent\M','Cres.');
  abbrev=regexp_replace(abbrev,'Court\M','Ct');
  abbrev=regexp_replace(abbrev,'Drive\M','Dr.');
  abbrev=regexp_replace(abbrev,'Lane\M','Ln.');
  abbrev=regexp_replace(abbrev,'Place\M','Pl.');
  abbrev=regexp_replace(abbrev,'Road\M','Rd.');
  abbrev=regexp_replace(abbrev,'Street\M','St.');
  abbrev=regexp_replace(abbrev,'Square\M','Sq.');

  abbrev=regexp_replace(abbrev,'Expressway\M','Expy');
  abbrev=regexp_replace(abbrev,'Freeway\M','Fwy');
  abbrev=regexp_replace(abbrev,'Parkway\M','Pkwy');

  abbrev=regexp_replace(abbrev,'North\M','N');
  abbrev=regexp_replace(abbrev,'South\M','S');
  abbrev=regexp_replace(abbrev,'West\M', 'W');
  abbrev=regexp_replace(abbrev,'East\M', 'E');

  abbrev=regexp_replace(abbrev,'Northwest\M', 'NW');
  abbrev=regexp_replace(abbrev,'Northeast\M', 'NE');
  abbrev=regexp_replace(abbrev,'Southwest\M', 'SW');
  abbrev=regexp_replace(abbrev,'Southeast\M', 'SE');

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
