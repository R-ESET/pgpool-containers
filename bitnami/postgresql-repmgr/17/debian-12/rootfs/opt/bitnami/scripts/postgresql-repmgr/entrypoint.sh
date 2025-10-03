#!/bin/bash
# Copyright Broadcom, Inc.
# SPDX-License-Identifier: APACHE-2.0

set -o errexit
set -o nounset
set -o pipefail

# Load Bitnami libs
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/libpostgresql.sh
. /opt/bitnami/scripts/librepmgr.sh
. /opt/bitnami/scripts/postgresql-env.sh

export MODULE=postgresql-repmgr
print_welcome_page
postgresql_enable_nss_wrapper

# Copy defaults
debug "Copying files from $POSTGRESQL_DEFAULT_CONF_DIR to $POSTGRESQL_CONF_DIR"
cp -nr "$POSTGRESQL_DEFAULT_CONF_DIR"/. "$POSTGRESQL_CONF_DIR"

# Setup on first run
if [[ "$*" = *"/opt/bitnami/scripts/postgresql-repmgr/run.sh"* ]]; then
    if [ ! -f "$POSTGRESQL_TMP_DIR/.initialized" ]; then
        info "** First run detected: skipping setup.sh (preserve cluster) **"
        touch "$POSTGRESQL_TMP_DIR/.initialized"
    else
        info "** Existing cluster detected: skipping setup.sh **"
    fi
fi

PGDATA="${POSTGRESQL_DATA_DIR:-/bitnami/postgresql/data}"
CONF_SRC="/opt/bitnami/postgresql/conf"

# Ensure base conf exists or exists
if [ ! -f "$PGDATA/postgresql.conf" ]; then
  echo "ℹ️ postgresql.conf missing, copying default"
  cp /opt/bitnami/postgresql/conf/postgresql.conf "$PGDATA/"
fi

# Ensure pg_hba.conf 
if [ ! -f "$PGDATA/pg_hba.conf" ]; then
  echo "ℹ️ pg_hba.conf missing, copying default"
  cp /opt/bitnami/postgresql/conf/pg_hba.conf "$PGDATA/"
fi

# Force include_dir only in postgresql.conf (NOT in pg_hba.conf)
if ! grep -q "include_dir = 'hba.d'" "$PGDATA/postgresql.conf"; then
  echo "include_dir = 'hba.d'" >> "$PGDATA/postgresql.conf"
fi

# Remove any bad 'include_dir' lines from pg_hba.conf
sed -i "/include_dir/d" "$PGDATA/pg_hba.conf"

# Create hba.d directory with safe defaults
mkdir -p "$PGDATA/hba.d"
cat > "$PGDATA/hba.d/00-local.conf" <<'EOF'
local   all             all                                     trust
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    replication     repmgr          0.0.0.0/0               md5
EOF

# Permissions
chown -R 1001:1001 "$PGDATA"
chmod 640 "$PGDATA/"*.conf
chmod 750 "$PGDATA/hba.d"
echo ""
exec "$@"
