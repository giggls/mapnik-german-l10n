#!/bin/bash

# generate psql extension "osml10n_thai_transcript"
# from plpgsql scripts
# version must be given as parameter
if [ $# -ne 2 ]; then
  echo "usage: gen_osml10n_thai_extension.sh <data_target_dir> <version>" >&2
  exit 1
fi

SCRIPTS=thaitranscript/*.sql

(
echo "-- complain if script is sourced in psql, rather than via CREATE EXTENSION"
echo '\echo Use "CREATE EXTENSION osml10n_thai_transcript" to load this file. \quit'
echo
) >>osml10n_thai_transcript--$2.sql

for f in $SCRIPTS; do
  bn=$(basename $f)
  echo "" >>osml10n_thai_transcript--$2.sql
  echo "-- pl/pgSQL code from file $bn -----------------------------------------------------------------" >>osml10n_thai_transcript--$2.sql
  cat $f >>osml10n_thai_transcript--$2.sql
done

