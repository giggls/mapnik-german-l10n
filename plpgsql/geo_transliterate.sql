/*
   osml10n_geo_translit
   
   a geolocation aware transliteration function if no koordinates are given
   fall back to generic transliteration 

   (c) 2015-2016 Sven Geggus <svn-osm@geggus.net>
   
   Licence AGPL http://www.gnu.org/licenses/agpl-3.0.de.html
   
   usage examples:
   select osml10n_geo_translit('東京',ST_Transform(ST_GeomFromText('POINT(137 35)',4326),3857));
    ---> "toukyou"
    
   select osml10n_geo_translit('東京');
    ---> "dōng jīng"
   
*/

CREATE or REPLACE FUNCTION osml10n_cc_transscript(name text, country text) RETURNS TEXT AS $$
  DECLARE
    thai_rm text;
  BEGIN
    CASE
      WHEN country='jp' THEN
        /* call osml10n_kanji_transcript only on cjk charakters
           not on hiragana and katakana
        */
        if osml10n_contains_cjk(name) THEN
          return osml10n_kanji_transcript(name);
        ELSE
          return osml10n_translit(name);
        END IF;
      WHEN country='th' THEN
        -- Call 'osml10n_thai_transcript' only if available
        IF EXISTS (SELECT 1 from pg_proc where proname = 'osml10n_thai_transcript') THEN
          thai_rm=osml10n_thai_transcript(name);
          IF (thai_rm IS NULL) THEN
            return osml10n_translit(name);
          ELSE
            return thai_rm;
          END IF;
        END IF;
        return osml10n_translit(name);
      ELSE
        return osml10n_translit(name);
    END CASE;
  END;
$$ LANGUAGE plpgsql STABLE;


CREATE or REPLACE FUNCTION osml10n_geo_translit(name text, place geometry DEFAULT NULL) RETURNS TEXT AS $$
  BEGIN
    -- RAISE LOG 'going to transliterate %', name;
    IF (place IS NULL) THEN
      return osml10n_translit(name);
    ELSE
    
    
      /* 
         Look up the country where the geometry is located
         
         This is likely slow and currently only needed for CJK
         and Thai language thus check for those alphabets first.
      
      */
      
      IF (osml10n_contains_thai(name)) THEN
        return osml10n_cc_transscript(name,'th');
      END IF;

      IF (osml10n_contains_cjk(name)) THEN
        return osml10n_cc_transscript(name,osml10n_get_country(place));
      END IF;

      return(osml10n_translit(name));

    END IF;
  END;
$$ LANGUAGE plpgsql STABLE;

