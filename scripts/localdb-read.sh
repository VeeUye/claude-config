#!/usr/bin/env bash
# Read-only sqlcmd against the local sql-server container (db_datareader only).
# Usage: localdb-read.sh -d <database> -Q "<query>"   or pipe SQL on stdin
set -euo pipefail

SQLCMDPASSWORD=$(security find-generic-password -s afs-localdb-reader -a claude_reader -w) || {
  echo "No Keychain entry afs-localdb-reader. Run ~/.claude/scripts/localdb-setup.sh first." >&2
  exit 1
}
export SQLCMDPASSWORD

exec docker --context desktop-linux exec -i -e SQLCMDPASSWORD sql-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U claude_reader -C -b -I -X1 -x "$@"
