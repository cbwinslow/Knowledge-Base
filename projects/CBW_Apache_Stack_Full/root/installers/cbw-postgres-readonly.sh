#!/usr/bin/env bash
set -euo pipefail; IFS=$'\n\t'
create_ro(){ db="$1"; user="$2"; pass="$3"; sudo -u postgres psql -v ON_ERROR_STOP=1 <<SQL
DO $$BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname='${user}') THEN
  CREATE ROLE ${user} LOGIN PASSWORD '${pass}';
END IF; END$$;
GRANT CONNECT ON DATABASE ${db} TO ${user};
\c ${db}
GRANT USAGE ON SCHEMA public TO ${user};
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ${user};
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ${user};
SQL
}
create_ro airflow airflow_ro "${AIRFLOW_RO_PASS:-airflow_ro_pw_change}"
create_ro superset superset_ro "${SUPERSET_RO_PASS:-superset_ro_pw_change}"
echo "[+] Read-only users created: airflow_ro, superset_ro"
