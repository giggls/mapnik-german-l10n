## Software requirements:

* GNU/Linux OS
* Postgresql 10 or newer, PostGIS 2 or newer
* Kanji Kana Simple Inverter library (http://kakasi.namazu.org/)
* ICU - International Components for Unicode library (http://site.icu-project.org/)

This code is developed on Debian 10.x and should also work on Debian
derivatives like Ubuntu and other GNU/Linux distributions.

If you are on Debian or Ubuntu all required libraries should be installed from
your distribution. Please do not compile them from source!

Microsoft Windows is currently not supported and I have no plans to do so.
If you feel an urgend need to port this code to Windows I would be happy to
take patches.

To install the l10n into your database the following steps are requered:

### 1. Install the libraries for the C/C++ stored procedures


The easiest way to do this on Debian/Ubuntu is to build packages and install
them:

```sh
make deb
```

To make this work you will need to install the required libraries:

```sh
sudo apt-get install devscripts equivs
sudo mk-build-deps -i debian/control
```     

On other Distributions it should work to use `make`/`make install`, given the
required libraries listed in `debian/control` have been installed.
I would be happy if somebody would contribute a spec-file for rpm based
distributions.

The build process will need to download country_osm_grid.sql from
https://www.nominatim.org/data/country_grid.sql.gz
If your computer is offline for some reason. Just download this file and
put it inside your build directory.

Thai transcript is a seperate extension because it is based on python
(https://pypi.org/project/tltk/) and installing
**postgresql-plpython3** is probably not an option for everybody.

If osml10n_thai_transcript is not installed transcription for thai language
will fall back to libicu which will not produce very good results.

To make osml10n_thai_transcript work tltk must be installed on the system
level using the pip (pip3) package manager:

```sh
sudo pip3 install tltk
```

### 2. Load the required extensions into your database
```sql
CREATE EXTENSION osml10n CASCADE;
CREATE EXTENSION osml10n_thai_transcript CASCADE;
```

If you already installed the previous version of this software use:
```sql
ALTER EXTENSION osml10n UPDATE;
ALTER EXTENSION osml10n_thai_transcript UPDATE;
```

**WARNING: This will only work from the previous version to the
current version, not across multiple versions.**

After installing or updating the extension you should be able to do the following:

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

```sql
yourdb=# select osml10n_thai_transcript('ถนนข้าวสาร');
 osml10n_thai_transcript
---------------------
 thanon khaosan
 (1 row)
```

To check if everything went well run the test script provided in the
tests/runtests_in_virtualenv.sh directory. As this test uses pg_virtualenv
it is not required to create a database to run the test.
