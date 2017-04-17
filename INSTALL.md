## Software requirements:

* GNU/Linux OS
* Postgresql 8.4 or 8.5, PostGIS 2.x
* Kanji Kana Simple Inverter library (http://kakasi.namazu.org/)
* ICU - International Components for Unicode library (http://site.icu-project.org/)

This code is developed on Debian 8.x and verified to also work on Ubuntu
14.04 and Ubuntu 16.04 only but should also work on other GNU/Linux
distributions.

All required libraries can be installed from their respective repositories.

Microsoft Windows is currently not supported and I have no plans to do so.
If you feel an urgend need to port this code to Windows I would be happy to
take patches.

To install the l10n into your databse the following steps are requered:

### 1. Install the libraries for the C/C++ stored procedures


The easiest way to to this on Debian/Ubuntu is to build packages and install
them:

```sh
make deb
```

To make this work you will need to install the required libraries:

sudo apt-get install devscripts equivs
sudo mk-build-deps -i debian/control

On other Distributions it should work to use `make`/`make install`, given the
required libraries listed in `debian/control` have been installed.
I would be happy if somebody would contribute a spec-file for rpm based
distributions.

The build process will need to download country_osm_grid.sql from
https://github.com/twain47/Nominatim/raw/master/data/country_osm_grid.sql
If your computer is offline for some reason. Just download this file and
put it inside your build directory.

### 2. Load the required extensions into your database
```sql
CREATE EXTENSION postgis;
CREATE EXTENSION hstore;
CREATE EXTENSION unaccent;
CREATE EXTENSION fuzzystrmatch;
CREATE EXTENSION osml10n;
```


Afterwards you should be able to do the following:

```sql
yourdb=# select osml10n_translit('北京');
 osml10n_translit
---------------
 běi jīng
 (1 row)
```

```sql
yourdb=# select osml10n_kanji_transcript('漢字');
 osml10n_kanji_transcript
---------------------
 kanji
 (1 row)
```

