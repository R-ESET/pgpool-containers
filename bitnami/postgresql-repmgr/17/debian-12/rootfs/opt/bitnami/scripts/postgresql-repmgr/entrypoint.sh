#!/bin/bash
# Copyright Broadcom, Inc. All Rights Reserved.
# SPDX-License-Identifier: APACHE-2.0

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
#set -o xtrace

# Load libraries
. /opt/bitnami/scripts/liblog.sh
. /opt/bitnami/scripts/libbitnami.sh
. /opt/bitnami/scripts/libpostgresql.sh
. /opt/bitnami/scripts/librepmgr.sh

# Load PostgreSQL & repmgr environment variables
. /opt/bitnami/scripts/postgresql-env.sh
export MODULE=postgresql-repmgr

print_welcome_page

# Enable the nss_wrapper settings
postgresql_enable_nss_wrapper

# We add the copy from default config in the entrypoint to not break users
# bypassing the setup.sh logic. If the file already exists do not overwrite (in
# case someone mounts a configuration file in /opt/bitnami/postgresql/conf)
debug "Copying files from $POSTGRESQL_DEFAULT_CONF_DIR to $POSTGRESQL_CONF_DIR"
cp -nr "$POSTGRESQL_DEFAULT_CONF_DIR"/. "$POSTGRESQL_CONF_DIR"

# ---- SAFETY PATCH ----
PGDATA="${POSTGRESQL_DATA_DIR:-/bitnami/postgresql/data}"
CONF_SRC="/opt/bitnami/postgresql/conf"

if [ ! -f "$PGDATA/pg_hba.conf" ]; then
  echo "ℹ️  Copying missing pg_hba.conf and postgresql.conf into $PGDATA"
  cp "$CONF_SRC/pg_hba.conf" "$PGDATA/"
  cp "$CONF_SRC/postgresql.conf" "$PGDATA/"
  chown 1001:1001 "$PGDATA/pg_hba.conf" "$PGDATA/postgresql.conf"
  chmod 640 "$PGDATA/pg_hba.conf" "$PGDATA/postgresql.conf"
fi

# Hand off to the final command (Postgres)
exec "$@"
