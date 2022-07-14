#  OSM map l10n functions
## (from German Mapnik style)

## ![This Repository is deprecated in favor of https://github.com/giggls/osml10n/](https://github.com/giggls/osml10n/)

All l10n functions from German Mapnik style are implemented as PL/pgSQL stored procedures
and are therefore usable in a renderer independent way.

For this reason they are now hosted in their own repository.

Currently the code consists of three parts:

1. An "Any-Latin" transliterate function using libicu
2. A japanese kanji transliterate function using libkakasi
3. A couple of PL/pgSQL functions which can be used to generate labels for
   map rendering.

See **INSTALL.md** file from sources for manual installation instructions.
If you just installed the debian package all you have to do now ist to enable
our extension in your PostgreSQL database as follows:

```sql
CREATE EXTENSION osml10n;
```

### API
The following functions are provided for use in map rendering:


__`osml10n_get_placename_from_tags(tags hstore, loc_in_brackets boolean, show_brackets boolean DEFAULT false, separator text DEFAULT chr(10), targetlang text DEFAULT 'de', place geometry DEFAULT NULL, name text DEFAULT NULL)`__
:	Will try its best to return a usable name pair with both a localized name and an on site name

__`osml10n_get_streetname_from_tags(tags hstore, loc_in_brackets boolean, show_brackets boolean DEFAULT false, separator text DEFAULT ' - ', targetlang text DEFAULT 'de', place geometry DEFAULT NULL, name text DEFAULT NULL)`__
:	Same as get_localized_placename_from_tags, but with some common abbreviations for street names (Straße->Str.), if name ist longer than 15 characters

__`osml10n_get_name_without_brackets_from_tags(tags hstore, loc_in_brackets boolean, targetlang text DEFAULT 'de', place geometry DEFAULT NULL, name text DEFAULT NULL)`__
:	Produces localized name only output (on site name will be discarded)

__`osml10n_get_country_name(tags hstore, separator text DEFAULT chr(10), targetlang text DEFAULT 'de')`__
:	Generate a combined country name from name:xx tags (targetlang plus official languages of the country)


A convenient way of using these functions is to hide them behind virtual columns using database views.

### Examples

```sql
select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',true) as name;
       -->	Москва́
       -->	Moskau
select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',false) as name;
       -->	Moskau
       -->	Москва́
select osml10n_get_placename_from_tags('"name"=>"القاهرة","name:de"=>"Kairo","int_name"=>"Cairo","name:en"=>"Cairo"',false) as name;
       -->	Kairo
       -->	القاهرة
select osml10n_get_placename_from_tags('name=>"Brixen Bressanone",name:de=>"Brixen",name:it=>"Bressanone"',false);
       -->	Brixen
       --> 	Bressanone
select osml10n_get_placename_from_tags('"name"=>"Roma","name:de"=>"Rom"',false) as name;
       -->	Rom
       -->	Roma
select osml10n_get_streetname_from_tags('"name"=>"Doktor-No-Straße"',false) as name;
       -->	Dr.-No-Str.
select osml10n_get_streetname_from_tags('"name"=>"Dr. No Street","name:de"=>"Professor-Doktor-No-Straße"',false) as name;
       -->	Prof.-Dr.-No-Str. - Dr. No St.
select osml10n_get_name_without_brackets_from_tags('"name"=>"Dr. No Street","name:de"=>"Doktor-No-Straße"') as name;
       -->	Doktor-No-Straße
select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка","name:en"=>"Vozdvizhenka Street"',true,true,' ','de') as name;
       -->	ул. Воздвиженка (Vozdvizhenka St.)
select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка"',true,true,' ','de') as name;
       -->	ул. Воздвиженка (ul. Vozdviženka)
select osml10n_get_streetname_from_tags('"name"=>"вулиця Молока"',true,false,' - ','de') as name;
       -->	вул. Молока - vul. Moloka
select osml10n_get_placename_from_tags('"name"=>"주촌  Juchon", "name:ko"=>"주촌","name:ko-Latn"=>"Juchon"',true) as name;
       -->	주촌
       -->	Juchon
select osml10n_get_placename_from_tags('"name"=>"주촌", "name:ko"=>"주촌","name:ko-Latn"=>"Juchon"',false) as name;
       -->	Juchon
       -->	J주촌
select osml10n_get_country_name('"ISO3166-1:alpha2"=>"IN","name:de"=>"Indien","name:hi"=>"भारत","name:en"=>"India"') as name;
       -->	Indien
       -->	भारत
       -->	India
```
