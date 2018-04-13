#!/bin/bash

DIR=$(dirname "$0")

# re-run us in pg_virtualenv if we do not already
if [[ $PGSYSCONFDIR != /tmp/pg_virtualenv* ]]; then
  pg_virtualenv $0
  exit 0
fi

createdb osml10n
echo "CREATE EXTENSION osml10n CASCADE; CREATE EXTENSION osml10n_thai_transcript CASCADE;" |psql osml10n
$DIR/runtests.sh osml10n
exit $?
