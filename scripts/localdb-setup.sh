#!/usr/bin/env bash
# One-off: creates least-privilege SQL logins for Claude in the local sql-server container.
# Passwords are generated here, stored in the macOS Keychain and never printed.
# Re-run to rotate passwords or to grant access to databases created since the last run.
set -euo pipefail

docker_context=desktop-linux
container=sql-server
sqlcmd=/opt/mssql-tools18/bin/sqlcmd

generate_password() {
  # Suffix guarantees SQL Server's complexity policy (upper, lower, digit)
  printf '%sAa1' "$(openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c 32)"
}

store_in_keychain() {
  local service=$1 account=$2 password=$3 trusted_applications=$4
  security delete-generic-password -s "$service" -a "$account" >/dev/null 2>&1 || true
  # Fed through stdin so the password never appears in the process list
  printf 'add-generic-password -s %s -a %s %s -w %s\n' "$service" "$account" "$trusted_applications" "$password" | security -i >/dev/null
  security find-generic-password -s "$service" -a "$account" >/dev/null 2>&1 || {
    echo "Failed to store $service in the Keychain. Re-run this script." >&2
    exit 1
  }
}

print_login_statements() {
  local login=$1 password=$2
  # printf is a builtin, so the password stays off disk and out of the process list
  printf "IF SUSER_ID('%s') IS NULL CREATE LOGIN %s WITH PASSWORD = '%s';\nELSE ALTER LOGIN %s WITH PASSWORD = '%s';\n" \
    "$login" "$login" "$password" "$login" "$password"
}

print_grant_statements() {
  # Quoted heredoc: contains no secrets, so the temp file bash 3.2 writes is harmless
  cat <<'SQL'
DECLARE @databaseName sysname, @statement nvarchar(max);
DECLARE userDatabases CURSOR LOCAL FAST_FORWARD FOR
  SELECT name FROM sys.databases WHERE database_id > 4 AND state_desc = 'ONLINE';

OPEN userDatabases;
FETCH NEXT FROM userDatabases INTO @databaseName;
WHILE @@FETCH_STATUS = 0
BEGIN
  SET @statement = N'USE ' + QUOTENAME(@databaseName) + N';
    IF DATABASE_PRINCIPAL_ID(''claude_reader'') IS NULL CREATE USER claude_reader FOR LOGIN claude_reader;
    IF DATABASE_PRINCIPAL_ID(''claude_writer'') IS NULL CREATE USER claude_writer FOR LOGIN claude_writer;
    ALTER ROLE db_datareader ADD MEMBER claude_reader;
    ALTER ROLE db_datareader ADD MEMBER claude_writer;
    ALTER ROLE db_datawriter ADD MEMBER claude_writer;';
  EXEC sp_executesql @statement;
  PRINT 'Granted access to ' + @databaseName;
  FETCH NEXT FROM userDatabases INTO @databaseName;
END
CLOSE userDatabases;
DEALLOCATE userDatabases;
SQL
}

reader_password=$(generate_password)
writer_password=$(generate_password)

read -rsp "SA password for the local sql-server container: " SQLCMDPASSWORD
echo
export SQLCMDPASSWORD

{
  echo 'SET NOCOUNT ON;'
  print_login_statements claude_reader "$reader_password"
  print_login_statements claude_writer "$writer_password"
  print_grant_statements
} | docker --context "$docker_context" exec -i -e SQLCMDPASSWORD "$container" "$sqlcmd" -S localhost -U sa -C -b

unset SQLCMDPASSWORD

store_in_keychain afs-localdb-reader claude_reader "$reader_password" ""
# No trusted applications: macOS shows a Keychain dialog every time the writer password is read
store_in_keychain afs-localdb-writer claude_writer "$writer_password" '-T ""'

echo "Done. Passwords stored in Keychain as afs-localdb-reader and afs-localdb-writer."
echo "When a write triggers the Keychain dialog, click Allow — never Always Allow."
