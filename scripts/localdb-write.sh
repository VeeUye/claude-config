#!/usr/bin/env bash
# Read/write sqlcmd against the local sql-server container (db_datareader + db_datawriter, no DDL).
# Claude Code is configured to always ask before running this.
# Usage: localdb-write.sh -d <database> -Q "<statement>"   or pipe SQL on stdin
set -euo pipefail

SQLCMDPASSWORD=$(security find-generic-password -s afs-localdb-writer -a claude_writer -w) || {
  echo "No Keychain entry afs-localdb-writer. Run ~/.claude/scripts/localdb-setup.sh first." >&2
  exit 1
}
export SQLCMDPASSWORD

exec docker --context desktop-linux exec -i -e SQLCMDPASSWORD sql-server /opt/mssql-tools18/bin/sqlcmd -S localhost -U claude_writer -C -b -I -X1 -x "$@"
