#  OSM map l10n functions
##(from german mapnik style)

All l10n functions from german mapnik style are implemented as PL/pgSQL stored procedures
and are therefore usable in a renderer independent way.

For this reason they are now hosted in their own repository.

Currently the code consists of three parts:

1. An "Any-Latin" transliterate funtion using libicu
2. A japanese kanji transliterate funtion using libkakasi
3. A couple of PL/pgSQL functions which can be used to generate labels for
   map rendering.

See **INSTALL.md** file from sources for manual installation instructions.
If you just installed the debian package all you have to do now ist to enable
our extension in your PostgreSQL database as follows:

```sql
CREATE EXTENSION osml10n;
```

For SQL usage examples have a look at `plpgsql/get_localized_name.sql`

### Quickstart:

An SQL query for rendering a primary highway may look like this:

```sql
select name,way
from highways
where highway='primary';
```

For a localized version it can be changed like this:
```sql
select osml10n_get_streetname(name,"name:de",int_name,"name:en",true,'de',way) as name,way
from highways
where highway='primary';
```   

It is also possible to hide the l10n functions in a view to make the query just look like
before.

