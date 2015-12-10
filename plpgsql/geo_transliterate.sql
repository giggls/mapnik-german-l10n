/*
   geo_transliterate
   
   a geolocation aware transliteration function if no koordinates are given
   fall back to generic transliteration 

   (c) 2015-2016 Sven Geggus <svn-osm@geggus.net>   
   
*/

CREATE or REPLACE FUNCTION geo_transliterate(name text, place geometry DEFAULT NULL) RETURNS TEXT AS $$
  DECLARE
    country text;
  BEGIN
    IF (place IS NULL) THEN
      return transliterate(name);
    ELSE
      /* 
         Look up the country where the geometry is located and call
         the specific transliteration function.
        
         Currently only japan is treated defferently, but other country
         specific transliteration functions can be added easily
      */
      country=get_country(place);

      CASE
        WHEN country='jp' THEN
          /* call kanji_transliterate only on cjk charakters
             not on hiragana and katakana
          */
          if contains_cjk(name) THEN
            return kanji_transliterate(name);
          ELSE
            return transliterate(name);
          END IF;
        ELSE
          return transliterate(name);
      END CASE;

      return country;
    END IF;
  END;
$$ LANGUAGE plpgsql;
