/*
renderer independent name localization
used in german mapnik style available at

https://github.com/giggls/openstreetmap-carto-de

(c) 2016-2020 Sven Geggus <svn-osm@geggus.net>

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
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT PARALLEL SAFE;

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
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT PARALLEL SAFE;

/*
   helper function "osml10n_contains_cyrillic"
  checks if string contains Cyrillic characters
  = 0x0400-0x04FF in unicode table
*/
CREATE or REPLACE FUNCTION osml10n_contains_cyrillic(text) RETURNS BOOLEAN AS $$
  DECLARE
    i integer;
    c integer;
  BEGIN
    FOR i IN 1..char_length($1) LOOP
      c = ascii(substr($1, i, 1));
      IF ((c > x'0400'::int) AND (c < x'04FF'::int)) THEN
        RETURN true;
      END IF;
    END LOOP;
    RETURN false;
  END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT PARALLEL SAFE;

/*
   helper function "osml10n_contains_thai"
  checks if string contains Thai language characters
  = 0x0E00-0x0E7F in unicode table
*/
CREATE or REPLACE FUNCTION osml10n_contains_thai(text) RETURNS BOOLEAN AS $$
  DECLARE
    i integer;
    c integer;
  BEGIN
    FOR i IN 1..char_length($1) LOOP
      c = ascii(substr($1, i, 1));
      IF ((c > x'0E00'::int) AND (c < x'0E7F'::int)) THEN
        RETURN true;
      END IF;
    END LOOP;
    RETURN false;
  END;
$$ LANGUAGE 'plpgsql' IMMUTABLE STRICT PARALLEL SAFE;
