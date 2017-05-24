## Software requirements:

* GNU/Linux OS
* Postgresql 8.4, PostGIS 2.x
* Kanji Kana Simple Inverter library (http://kakasi.namazu.org/)
* ICU - International Components for Unicode library (http://site.icu-project.org/)

This code is currently tested on Debian/Ubuntu only but should also work on
other GNU/Linux dsitributions.

All required libraries can be installed from their respective repositories.

Microsoft Windows is currently not supported and I have no plans to do so.
If you feel an urgend need to port this code to Windows I would be happy to
take patches.

To install the l10n into your databse the following steps are requered:

### 1. Install the libraries for the C/C++ stored procedures


The easiest way to to this on Debian/Ubuntu is to build packages and install
them:

```sh
for p in *translit; do pushd $p; dpkg-buildpackage -b ; popd; done
```

To make this work you will need to install the required libraries:
`libicu-dev, libkakasi2-dev, postgresql-server-dev-9.4`

On other Distributions use `make/make install`.

### 2. Enable the C/C++ stored procedures (requires database admin privileges)


On a psql shell issue the following command (will need superuser privileges):

```sql
CREATE or REPLACE FUNCTION kanji_transliterate(text)
RETURNS text AS '$libdir/kanjitranslit.so', 'kanji_transliterate'
LANGUAGE C STRICT;
```

```sql
CREATE or REPLACE FUNCTION transliterate(text)
RETURNS text AS '$libdir/utf8translit.so', 'transliterate'
LANGUAGE C STRICT;
```

Afterwards you should be able to do the following:

```sql
yourdb=# select transliterate('北京');
 transliterate 
---------------
 běi jīng
 (1 row)
```

```sql
yourdb=# select kanji_transliterate('漢字');
 kanji_transliterate 
---------------------
 kanji
 (1 row)
```

### 3. Enable the PL/pgSQL stored procedures

To do this all sql files from plpgsql diectory have to be applied to your
database:
```
pushd plpgsql; for sql in *.sql; do psql -f $sql yourdb; done; popd
```



