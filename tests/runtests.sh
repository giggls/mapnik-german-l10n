#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

#
# This test needs a database with osml10n extension enabled
#
#

if [ $# -ne 1 ]; then
  echo "usage: $0 <dbname>"
  exit 1
fi

cd "$(dirname "$0")"

# check if commands we need are available
for cmd in psql uconv; do
  if ! command -v $cmd >/dev/null; then
    echo -e "[\033[1;31mERROR\033[0;0m]: command >>$cmd<< not found, please install!"
    exit 1
  fi
done

DB=$1
exitval=0
passed=0
failed=0

# STDIN - function to run (without "select" keyword)
# $1 expected
# $2 optional "unicode" param to normalize unicode
function printresult() {
  local res
  local query
  query="SELECT $(cat /dev/stdin);"
  echo "$query"
  res="$(echo "$query" | psql -X -t -A "$DB")"
  if [[ ! -z "${2:-}" ]]; then
    # unicode normalize
    res=$(echo "$res" | uconv -x Any-NFC)
  fi
  if [[ "$res" == "$1" ]]; then
    echo -n -e "[\033[0;32mOK\033[0;0m]     "
    ((passed=passed+1))
  else
    echo -n -e "[\033[1;31mFAILED\033[0;0m] "
    ((failed=failed+1))
    exitval=1
  fi
  echo -e "(expected >$1<, got >$res<)"
}

printresult "kanji 100 abc" <<EOT
  osml10n_kanji_transcript('漢字 100 abc')
EOT
printresult "hàn zì 100 abc" <<'EOT'
  osml10n_translit('漢字 100 abc')
EOT
printresult "thai thanon khaosan 100" <<'EOT'
  osml10n_thai_transcript('thai ถนนข้าวสาร 100')
EOT
printresult "hongsamut prachachon" <<'EOT'
  osml10n_thai_transcript('ห้องสมุดประชาชน')
EOT
printresult "Moskvá" unicode <<'EOT'
  osml10n_translit('Москва́')
EOT
printresult "hàn zì 100 abc" <<'EOT'
  osml10n_translit('漢字 100 abc')
EOT
printresult "de" <<'EOT'
  osml10n_get_country(ST_GeomFromText('POINT(9 49)', 4326))
EOT
printresult "th" <<'EOT'
  osml10n_get_country(ST_GeomFromText('POINT(100 16)', 4326))
EOT
printresult "hk" <<'EOT'
  osml10n_get_country(ST_GeomFromText('POINT(114.2 22.3)', 4326))
EOT
printresult "mo" <<'EOT'
  osml10n_get_country(ST_GeomFromText('POINT(113.6 22.2)', 4326))
EOT
printresult "toukyou" <<'EOT'
  osml10n_geo_translit('東京',ST_GeomFromText('POINT(140 40)', 4326))
EOT
printresult "dōng jīng" <<'EOT'
  osml10n_geo_translit('東京',ST_GeomFromText('POINT(100 30)', 4326))
EOT
printresult "hongsamut prachachon" <<'EOT'
  osml10n_geo_translit('ห้องสมุดประชาชน',ST_GeomFromText('POINT(100 16)', 4326))
EOT
printresult "‪Москва́ - Moskau‬" unicode <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',true,false, ' - ')
EOT
printresult "‪Moskau|Москва́‬" unicode <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',false,false, '|')
EOT
printresult "‪Kairo|القاهرة‬" <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"القاهرة","name:de"=>"Kairo","int_name"=>"Cairo","name:en"=>"Cairo"',false,false, '|')
EOT
printresult "‪Brüssel|Bruxelles‬" <<'EOT'
  osml10n_get_placename_from_tags('name=>"Bruxelles - Brussel",name:de=>Brüssel,name:en=>Brussels,name:xx=>Brussel,name:af=>Brussel,name:fr=>Bruxelles,name:fo=>Brussel',false,false, '|')
EOT

# upstream carto style database layout
printresult "‪Brüssel|Bruxelles‬" <<'EOT'
  osml10n_get_placename_from_tags('name:de=>Brüssel,name:en=>Brussels,name:xx=>Brussel,name:af=>Brussel,name:fr=>Bruxelles,name:fo=>Brussel',false,false, '|','de',NULL,'Bruxelles - Brussel')
EOT
printresult "‪Brixen|Bressanone‬" <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"Brixen Bressanone","name:de"=>"Brixen","name:it"=>"Bressanone"',false,false, '|')
EOT

# This is a fictual tagging as I do not know of an italian speaking town
# where the names are that similar
printresult "‪Merano|Meran‬" <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"Merano - Meran","name:de"=>"Meran","name:it"=>"Merano"',true,false, '|') as name
EOT
printresult "‪Meran|Merano‬" <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"Meran - Merano","name:de"=>"Meran","name:it"=>"Merano"',true,false, '|') as name
EOT
printresult "‪Rom|Roma‬" <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"Roma","name:de"=>"Rom"',false,false, '|')
EOT
printresult "‪Prof.-Dr.-No-Str. - Dr. No St.‬" <<'EOT'
  osml10n_get_streetname_from_tags('"name"=>"Dr. No Street","name:de"=>"Professor-Doktor-No-Straße"',false)
EOT
printresult "Doktor-No-Straße" <<'EOT'
  osml10n_get_name_without_brackets_from_tags('"name"=>"Dr. No Street","name:de"=>"Doktor-No-Straße"')
EOT
printresult "Doktor-No-Straße" <<'EOT'
  osml10n_get_name_without_brackets_from_tags('"name:de"=>"Doktor-No-Straße"','de',NULL,'Dr. No Street')
EOT

for CSV_FILE in *.csv; do
  IFS=,
  echo -e "\n---- Abbreviations from $CSV_FILE ----"
  while read -r nameIn nameExpected
  do
    printresult "${nameExpected}" <<EOT
  osml10n_get_streetname_from_tags('"name"=>"${nameIn}"',false)
EOT
  done < "$CSV_FILE"
done

printresult "‪ул. Воздвиженка (Vozdvizhenka St.)‬" <<'EOT'
  osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка","name:en"=>"Vozdvizhenka Street"',true,true,' ','de')
EOT
#  Russian language
printresult "‪ул. Воздвиженка (ul. Vozdviženka)‬" <<'EOT'
  osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка"',true,true,' ','de')
EOT
# Belarusian language (AFAIK)
printresult "‪вул. Молока - vul. Moloka‬" <<'EOT'
  osml10n_get_streetname_from_tags('"name"=>"вулиця Молока"',true,false,' - ','de')
EOT
# upstream carto style database layout
printresult "‪вул. Молока - vul. Moloka‬" <<'EOT'
  osml10n_get_streetname_from_tags('',true,false,' - ','de',NULL,'вулиця Молока')
EOT
printresult "‪주촌|Juchon‬" <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"주촌  Juchon", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',true,false,'|')
EOT
printresult "‪Juchon|주촌‬" <<'EOT'
  osml10n_get_placename_from_tags('"name"=>"주촌", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',false,false,'|')
EOT
printresult "‪ဘုရားကိုင်လမ်း|Pha Yar Kai Rd.‬" <<'EOT'
  osml10n_get_streetname_from_tags('"name"=>"ဘုရားကိုင်လမ်း Pha Yar Kai Road", "highway"=>"secondary", "name:en"=>"Pha Yar Kai Road", "name:my"=>"ဘုရားကိုင်လမ်း"',true,false,'|')
EOT
printresult "‪ဘုရားကိုင်လမ်း|Pha Yar Kai Rd.‬" <<'EOT'
  osml10n_get_streetname_from_tags('"name"=>"ဘုရားကိုင်လမ်း", "highway"=>"secondary", "name:en"=>"Pha Yar Kai Road", "name:my"=>"ဘုရားကိုင်လမ်း"',true,false,'|')
EOT
printresult "Indien|भारत|India" <<'EOT'
  osml10n_get_country_name('"ISO3166-1:alpha2"=>"IN","name:de"=>"Indien","name:hi"=>"भारत","name:en"=>"India"','|')
EOT

echo -e "\n$passed tests passed $failed tests failed."

exit $exitval
