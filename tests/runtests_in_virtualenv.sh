#!/usr/bin/env bash
set -e

DIR=$(dirname "$0")

# re-run us in pg_virtualenv if we do not already
if [ -z "$PGSYSCONFDIR" ]; then
  # exec this because we are interested in the return value of pg_virtualenv
  exec pg_virtualenv "$0"
fi

createdb osml10n
echo "CREATE EXTENSION osml10n CASCADE; CREATE EXTENSION osml10n_thai_transcript CASCADE;" |psql osml10n
"$DIR/runtests.sh" osml10n
