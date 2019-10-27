#!/bin/bash
#
# This test needs a databse with osml10n extension enabled
#
#

if [ $# -ne 1 ]; then
  echo "usage: $0 <dbname>"
  exit 1
fi

cd $(dirname "$0")

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

# $1 result
# $2 expected
function printresult() {
  if [ "$1" = "$2" ]; then
    echo -n -e "[\033[0;32mOK\033[0;0m]     "
    ((passed++))
  else
    echo -n -e "[\033[1;31mFAILED\033[0;0m] "
    ((failed++))
    exitval=1
  fi
  echo -e "(expected >$2<, got >$1<)"
}

echo "calling select osml10n_kanji_transcript('漢字 100 abc');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_kanji_transcript('漢字 100 abc');
EOF
)
printresult "$res" "kanji 100 abc"

echo "calling select osml10n_translit('漢字 100 abc');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_translit('漢字 100 abc');
EOF
)
printresult "$res" "hàn zì 100 abc"

echo "calling select osml10n_thai_transcript('thai ถนนข้าวสาร 100');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_thai_transcript('thai ถนนข้าวสาร 100');
EOF
)
printresult "$res" "thai thanon khaosan 100"

echo "calling select osml10n_thai_transcript('ห้องสมุดประชาชน');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_thai_transcript('ห้องสมุดประชาชน');
EOF
)
printresult "$res" "hongsamut prachachon"

echo "calling select osml10n_translit('Москва́');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_translit('Москва́');
EOF
)
# unicode normalize
res=$(echo $res | uconv -x Any-NFC)
printresult "$res" "Moskvá"

echo "calling select osml10n_translit('漢字 100 abc');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_translit('漢字 100 abc');
EOF
)
printresult "$res" "hàn zì 100 abc"

echo "calling select osml10n_get_country(ST_GeomFromText('POINT(9 49)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_country(ST_GeomFromText('POINT(9 49)', 4326));
EOF
)
printresult "$res" "de"

echo "calling select osml10n_get_country(ST_GeomFromText('POINT(100 16)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_country(ST_GeomFromText('POINT(100 16)', 4326));
EOF
)
printresult "$res" "th"

echo "calling select osml10n_geo_translit('東京',ST_GeomFromText('POINT(140 40)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_geo_translit('東京',ST_GeomFromText('POINT(140 40)', 4326));
EOF
)
printresult "$res" "toukyou"

echo "calling select osml10n_geo_translit('東京',ST_GeomFromText('POINT(100 30)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_geo_translit('東京',ST_GeomFromText('POINT(100 30)', 4326));
EOF
)
printresult "$res" "dōng jīng"

echo "calling select osml10n_geo_translit('ห้องสมุดประชาชน',ST_GeomFromText('POINT(100 16)', 4326));"
res=$(psql -X -t -A $DB <<EOF
select osml10n_geo_translit('ห้องสมุดประชาชน',ST_GeomFromText('POINT(100 16)', 4326));
EOF
)
printresult "$res" "hongsamut prachachon"

echo "select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',true,false, ' - ');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',true,false, ' - ');
EOF
)
# unicode normalize
res=$(echo $res | uconv -x Any-NFC)
printresult "$res" "‪Москва́ - Moskau‬"

echo "select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Москва́","name:de"=>"Moskau","name:en"=>"Moscow"',false,false, '|');
EOF
)
# unicode normalize
res=$(echo $res | uconv -x Any-NFC)
printresult "$res" "‪Moskau|Москва́‬"

echo "osml10n_get_placename_from_tags('"name"=>"القاهرة","name:de"=>"Kairo","int_name"=>"Cairo","name:en"=>"Cairo"',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"القاهرة","name:de"=>"Kairo","int_name"=>"Cairo","name:en"=>"Cairo"',false,false, '|');
EOF
)
printresult "$res" "‪Kairo|القاهرة‬"

echo "select osml10n_get_placename_from_tags('name=>"Bruxelles - Brussel",name:de=>Brüssel,name:en=>Brussels,name:xx=>Brussel,name:af=>Brussel,name:fr=>Bruxelles,name:fo=>Brussel',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('name=>"Bruxelles - Brussel",name:de=>Brüssel,name:en=>Brussels,name:xx=>Brussel,name:af=>Brussel,name:fr=>Bruxelles,name:fo=>Brussel',false,false, '|');
EOF
)
printresult "$res" "‪Brüssel|Bruxelles‬"

# upstream carto style database layout
echo "select osml10n_get_placename_from_tags('name:de=>Brüssel,name:en=>Brussels,name:xx=>Brussel,name:af=>Brussel,name:fr=>Bruxelles,name:fo=>Brussel',false,false, '|','de',NULL,'Bruxelles - Brussel');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('name:de=>Brüssel,name:en=>Brussels,name:xx=>Brussel,name:af=>Brussel,name:fr=>Bruxelles,name:fo=>Brussel',false,false, '|','de',NULL,'Bruxelles - Brussel');
EOF
)
printresult "$res" "‪Brüssel|Bruxelles‬"

echo "select osml10n_get_placename_from_tags('"name"=>"Brixen Bressanone","name:de"=>"Brixen","name:it"=>"Bressanone"',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Brixen Bressanone","name:de"=>"Brixen","name:it"=>"Bressanone"',false,false, '|');
EOF
)
printresult "$res" "‪Brixen|Bressanone‬"

# This is a fictual tagging as I do not know of an italian speaking town
# where the names are that similar
echo "select osml10n_get_placename_from_tags('"name"=>"Merano - Meran","name:de"=>"Meran","name:it"=>"Merano"',true,false, '|') as name;"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Merano - Meran","name:de"=>"Meran","name:it"=>"Merano"',true,false, '|') as name;
EOF
)
printresult "$res" "‪Merano|Meran‬"

echo "select osml10n_get_placename_from_tags('"name"=>"Meran - Merano","name:de"=>"Meran","name:it"=>"Merano"',true,false, '|') as name;"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Meran - Merano","name:de"=>"Meran","name:it"=>"Merano"',true,false, '|') as name;
EOF
)
printresult "$res" "‪Meran|Merano‬"

echo "select osml10n_get_placename_from_tags('"name"=>"Roma","name:de"=>"Rom"',false,false, '|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"Roma","name:de"=>"Rom"',false,false, '|');
EOF
)
printresult "$res" "‪Rom|Roma‬"

echo "select osml10n_get_streetname_from_tags('"name"=>"Dr. No Street","name:de"=>"Professor-Doktor-No-Straße"',false);"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"Dr. No Street","name:de"=>"Professor-Doktor-No-Straße"',false);
EOF
)
printresult "$res" "‪Prof.-Dr.-No-Str. - Dr. No St.‬"

echo "select osml10n_get_name_without_brackets_from_tags('"name"=>"Dr. No Street","name:de"=>"Doktor-No-Straße"');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_name_without_brackets_from_tags('"name"=>"Dr. No Street","name:de"=>"Doktor-No-Straße"');
EOF
)
printresult "$res" "Doktor-No-Straße"

echo "select osml10n_get_name_without_brackets_from_tags('"name:de"=>"Doktor-No-Straße"','de',NULL,'Dr. No Street');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_name_without_brackets_from_tags('"name:de"=>"Doktor-No-Straße"','de',NULL,'Dr. No Street');
EOF
)
printresult "$res" "Doktor-No-Straße"

IFS=,
echo -e "\n---- German abbreviations, data from de_test.csv ----"
while read nameIn nameExpected
do
  stmt="select osml10n_get_streetname_from_tags('\"name\"=>\"${nameIn}\"',false);"
  echo ${stmt}
  res=$(psql -X -t -A $DB -c "${stmt}")
  printresult "$res" "${nameExpected}"
done < de_tests.csv

IFS=,
echo -e "\n---- English abbreviations, data from en_test.csv ----"
while read nameIn nameExpected
do
  stmt="select osml10n_get_streetname_from_tags('\"name\"=>\"${nameIn}\"',false);"
  echo ${stmt}
  res=$(psql -X -t -A $DB -c "${stmt}")
  printresult "$res" "${nameExpected}"
done < en_tests.csv

echo -e "\n---- French abbreviations, data from fr_test.csv ----"
while read nameIn nameExpected
do
  stmt="select osml10n_get_streetname_from_tags('\"name\"=>\"${nameIn}\"',false);"
  echo ${stmt}
  res=$(psql -X -t -A $DB -c "${stmt}")
  printresult "$res" "${nameExpected}"
done < fr_tests.csv

echo -e "\n---- Dutch abbreviations, data from nl_test.csv ----"
while read nameIn nameExpected
do
  stmt="select osml10n_get_streetname_from_tags('\"name\"=>\"${nameIn}\"',false);"
  echo ${stmt}
  res=$(psql -X -t -A $DB -c "${stmt}")
  printresult "$res" "${nameExpected}"
done < nl_tests.csv

echo

echo "select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка","name:en"=>"Vozdvizhenka Street"',true,true,' ','de');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка","name:en"=>"Vozdvizhenka Street"',true,true,' ','de');
EOF
)
printresult "$res" "‪ул. Воздвиженка (Vozdvizhenka St.)‬"

#  Russian language
echo "select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка"',true,true,' ','de');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"улица Воздвиженка"',true,true,' ','de');
EOF
)
printresult "$res" "‪ул. Воздвиженка (ul. Vozdviženka)‬"

# Belarusian language (AFAIK)
echo "select osml10n_get_streetname_from_tags('"name"=>"вулиця Молока"',true,false,' - ','de');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"вулиця Молока"',true,false,' - ','de');
EOF
)
printresult "$res" "‪вул. Молока - vul. Moloka‬"

# upstream carto style database layout
echo "select osml10n_get_streetname_from_tags('',true,false,' - ','de',NULL,'вулиця Молока');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('',true,false,' - ','de',NULL,'вулиця Молока');
EOF
)
printresult "$res" "‪вул. Молока - vul. Moloka‬"

echo "select osml10n_get_placename_from_tags('"name"=>"주촌  Juchon", "name:ko"=>"주촌","name:ko-Latn"=>"Juchon"',true,false,'|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"주촌  Juchon", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',true,false,'|');
EOF
)
printresult "$res" "‪주촌|Juchon‬"

echo "select osml10n_get_placename_from_tags('"name"=>"주촌", "name:ko"=>"주촌","name:ko-Latn"=>"Juchon"',false,false,'|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_placename_from_tags('"name"=>"주촌", "name:ko"=>"주촌","name:ko_rm"=>"Juchon"',false,false,'|');
EOF
)
printresult "$res" "‪Juchon|주촌‬"

echo "select osml10n_get_streetname_from_tags('"name"=>"ဘုရားကိုင်လမ်း Pha Yar Kai Road", "highway"=>"secondary", "name:en"=>"Pha Yar Kai Road", "name:my"=>"ဘုရားကိုင်လမ်း"',true,false,'|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"ဘုရားကိုင်လမ်း Pha Yar Kai Road", "highway"=>"secondary", "name:en"=>"Pha Yar Kai Road", "name:my"=>"ဘုရားကိုင်လမ်း"',true,false,'|');
EOF
)
printresult "$res" "‪ဘုရားကိုင်လမ်း|Pha Yar Kai Rd.‬"

echo "select osml10n_get_streetname_from_tags('"name"=>"ဘုရားကိုင်လမ်း", "highway"=>"secondary", "name:en"=>"Pha Yar Kai Road", "name:my"=>"ဘုရားကိုင်လမ်း"',true,false,'|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_streetname_from_tags('"name"=>"ဘုရားကိုင်လမ်း", "highway"=>"secondary", "name:en"=>"Pha Yar Kai Road", "name:my"=>"ဘုရားကိုင်လမ်း"',true,false,'|');
EOF
)
printresult "$res" "‪ဘုရားကိုင်လမ်း|Pha Yar Kai Rd.‬"

echo "select osml10n_get_country_name('"ISO3166-1:alpha2"=>"IN","name:de"=>"Indien","name:hi"=>"भारत","name:en"=>"India"','|');"
res=$(psql -X -t -A $DB <<EOF
select osml10n_get_country_name('"ISO3166-1:alpha2"=>"IN","name:de"=>"Indien","name:hi"=>"भारत","name:en"=>"India"','|');
EOF
)
printresult "$res" "Indien|भारत|India"

echo -e "\n$passed tests passed $failed tests failed."

exit $exitval

