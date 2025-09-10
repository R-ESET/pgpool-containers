  # Copyright Broadcom, Inc. All Rights Reserved.
  # SPDX-License-Identifier: APACHE-2.0

  FROM docker.io/bitnami/minideb:bookworm

  ARG DOWNLOADS_URL="downloads.bitnami.com/files/stacksmith"
  ARG TARGETARCH

  LABEL com.vmware.cp.artifact.flavor="sha256:c50c90cfd9d12b445b011e6ad529f1ad3daea45c26d20b00732fae3cd71f6a83" \
        org.opencontainers.image.base.name="docker.io/bitnami/minideb:bookworm" \
        org.opencontainers.image.created="2025-08-14T16:37:45Z" \
        org.opencontainers.image.description="Application packaged by Broadcom, Inc." \
        org.opencontainers.image.documentation="https://github.com/bitnami/containers/tree/main/bitnami/postgresql-repmgr/README.md" \
        org.opencontainers.image.source="https://github.com/bitnami/containers/tree/main/bitnami/postgresql-repmgr" \
        org.opencontainers.image.title="postgresql-repmgr" \
        org.opencontainers.image.vendor="Broadcom, Inc." \
        org.opencontainers.image.version="17.6.0"

  ENV HOME="/" \
      OS_ARCH="${TARGETARCH:-amd64}" \
      OS_FLAVOUR="debian-12" \
      OS_NAME="linux"

  COPY prebuildfs /
  SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]
  # Install required system packages and dependencies
  RUN install_packages ca-certificates curl libbrotli1 libbsd0 libcom-err2 libcurl4 libedit2 libffi8 libgcc-s1 libgmp10 libgnutls30 libgssapi-krb5-2 libhogweed6 libicu72 libidn2-0 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 libldap-2.5-0 liblz4-1 liblzma5 libmd0 libnettle8 libnghttp2-14 libp11-kit0 libpcre3 libpsl5 libreadline8 librtmp1 libsasl2-2 libsqlite3-0 libssh2-1 libssl3 libstdc++6 libtasn1-6 libtinfo6 libunistring2 libuuid1 libxml2 libxslt1.1 libzstd1 locales procps zlib1g supervisor gosu

  RUN set -eux; \
    mkdir -p /tmp/bitnami/pkg/cache/ && cd /tmp/bitnami/pkg/cache/ ; \
    COMPONENTS=( \
      "postgresql-17.6.0-0-linux-${OS_ARCH}-debian-12" \
      "postgresql-repmgr-17.6.0-0-linux-${OS_ARCH}-debian-12" \
    ) ; \
    for COMPONENT in "${COMPONENTS[@]}"; do \
      echo ">>> Downloading $COMPONENT from $DOWNLOADS_URL"; \
      curl -SsLf "https://${DOWNLOADS_URL}/${COMPONENT}.tar.gz" -O ; \
      curl -SsLf "https://${DOWNLOADS_URL}/${COMPONENT}.tar.gz.sha256" -O ; \
      sha256sum -c "${COMPONENT}.tar.gz.sha256" ; \
      tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner ; \
      rm -f "${COMPONENT}.tar.gz" "${COMPONENT}.tar.gz.sha256" ; \
    done
    
  RUN apt-get update && apt-get upgrade -y && \
      apt-get clean && rm -rf /var/lib/apt/lists /var/cache/apt/archives
  RUN chmod g+rwX /opt/bitnami
  RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true
  RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && \
      DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales && \
      echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
  RUN echo 'en_GB.UTF-8 UTF-8' >> /etc/locale.gen
  RUN uninstall_packages curl

  COPY rootfs /
  RUN /opt/bitnami/scripts/postgresql-repmgr/postunpack.sh
  RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && \
      DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales && \
      echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
  RUN echo 'en_GB.UTF-8 UTF-8' >> /etc/locale.gen
  RUN /opt/bitnami/scripts/locales/generate-locales.sh
  ENV APP_VERSION="17.6.0" \
      BITNAMI_APP_NAME="postgresql-repmgr" \
      LANG="en_US.UTF-8" \
      LANGUAGE="en_US:en" \
      NSS_WRAPPER_LIB="/opt/bitnami/common/lib/libnss_wrapper.so" \
      PATH="/opt/bitnami/postgresql/bin:/opt/bitnami/repmgr/bin:$PATH"

  RUN mkdir -p /opt/bitnami/repmgr/tmp \
  && chown -R 1001:1001 /opt/bitnami/repmgr/tmp \
  && chmod 775 /opt/bitnami/repmgr/tmp



# Force repmgrd PID path Bitnami expect
RUN printf "\nrepmgrd_pid_file='/opt/bitnami/repmgr/tmp/repmgr.pid'\n" \
    >> /opt/bitnami/repmgr/conf/repmgr.conf

ENV TMPDIR="/opt/bitnami/repmgr/tmp" \
    REPMGRD_PIDFILE="/opt/bitnami/repmgr/tmp/repmgr.pid"

# Root entrypoint: fix Railway volume perms each start, then drop to 1001
COPY <<'EOF' /opt/bitnami/scripts/repmgr-root-entrypoint.sh
#!/bin/sh
set -eu

# Ensure dirs exist even if volumes replaced them
mkdir -p /opt/bitnami/postgresql/conf /opt/bitnami/postgresql/logs \
         /opt/bitnami/repmgr/tmp       /bitnami/postgresql \
         /opt/bitnami/postgresql/tmp

# Take ownership of mounted paths so uid 1001 can write configs/data/PIDs
chown -R 1001:1001 /opt/bitnami/postgresql /opt/bitnami/repmgr /bitnami || true
chmod -R 775 /opt/bitnami/postgresql/conf /opt/bitnami/postgresql/logs \
             /opt/bitnami/repmgr/tmp /opt/bitnami/postgresql/tmp || true

# Clean stale PIDs (repmgr + postgres)
rm -f "${REPMGRD_PIDFILE:-/opt/bitnami/repmgr/tmp/repmgr.pid}" /tmp/repmgrd.pid 2>/dev/null || true
PGDATA="${POSTGRESQL_DATA_DIR:-/bitnami/postgresql/data}"
rm -f "$PGDATA/postmaster.pid" "$PGDATA"/postmaster.opts 2>/dev/null || true

# If no cluster yet, make sure PGDATA is truly empty so pg_basebackup can populate it this was deleting database
# if [ ! -f "$PGDATA/PG_VERSION" ]; then
#   find "$PGDATA" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
# fi

if [ ! -f "$PGDATA/PG_VERSION" ]; then
  if [ -z "$(ls -A "$PGDATA" 2>/dev/null)" ]; then
    echo "ℹ️  PG_VERSION not found, but $PGDATA is empty."
    echo "ℹ️  Initializing a fresh PostgreSQL cluster..."
    /opt/bitnami/scripts/postgresql-repmgr/setup.sh
  else
    echo "❌ ERROR: PG_VERSION not found in $PGDATA but directory is not empty!"
    echo "❌ Refusing to start to protect existing data."
    echo "❌ Please investigate or clear the directory manually if you intend to reinit."
    exit 1
  fi
fi

# Ensure a valid unix socket directory (default to /tmp if not set)
PGCONF=/opt/bitnami/postgresql/conf
if [ -f "$PGCONF/postgresql.conf" ]; then
  if grep -q "^[[:space:]]*unix_socket_directories" "$PGCONF/postgresql.conf"; then
    SOCK_DIR="$(awk -F= '/^[[:space:]]*unix_socket_directories/ {gsub(/'\''|"/,"",$2); gsub(/[[:space:]]/,"",$2); print $2}' "$PGCONF/postgresql.conf" 2>/dev/null || echo)"
    if [ -n "$SOCK_DIR" ] && [ "$SOCK_DIR" != "/tmp" ]; then
      mkdir -p "$SOCK_DIR" && chmod 775 "$SOCK_DIR" || true
      chown -R 1001:1001 "$SOCK_DIR" || true
    fi
  else
    printf "\nunix_socket_directories = '/tmp'\n" >> "$PGCONF/postgresql.conf"
  fi
fi

# ----- HBA include at runtime (safe for pg0/pg1/pg2) -----
HBA_MAIN=/opt/bitnami/postgresql/conf/pg_hba.conf
HBA_DIR=/opt/bitnami/postgresql/conf/hba.d
mkdir -p "$HBA_DIR"

# Ensure pg_hba.conf includes the directory (PG 16+/17 support include_dir)
if [ -f "$HBA_MAIN" ]; then
  if ! grep -q "include_dir '$HBA_DIR'" "$HBA_MAIN"; then
    # try in-place; if sed fails (first boot), just append
    sed -i "1i include_dir '$HBA_DIR'" "$HBA_MAIN" 2>/dev/null || \
      printf "include_dir '%s'\n" "$HBA_DIR" >> "$HBA_MAIN"
  fi
else
  printf "include_dir '%s'\n" "$HBA_DIR" > "$HBA_MAIN"
fi

# Minimal local/loopback & replication entries so the node can become "ready"
cat > "$HBA_DIR/00-local.conf" <<'HBA'
local   all             all                                     trust
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
host    replication     repmgr          0.0.0.0/0               md5
HBA

# owner/perm sanity (Bitnami runs as uid 1001; Railway volumes mount as root)
chown -R 1001:1001 "$HBA_DIR" "$HBA_MAIN" || true
chmod 640 "$HBA_DIR"/00-local.conf "$HBA_MAIN" || true
# -rw-r----- 1 1001 1001  0 Mar  1 12:00 /opt/bitnami/postgresql/conf/hba.d/00-local.conf
# -rw-r----- 1 1001 1001  0 Mar  1 12:00 /opt/bitnami/postgresql/conf/pg_hba.conf

# Hand off to Bitnami's entrypoint as the non-root user (uid:gid 1001)
exec gosu 1001:1001 /opt/bitnami/scripts/postgresql-repmgr/entrypoint.sh "$@"
EOF
RUN chmod +x /opt/bitnami/scripts/repmgr-root-entrypoint.sh

# IMPORTANT: run as root so we can chown at runtime on Railway volumes
USER root
ENTRYPOINT ["/opt/bitnami/scripts/repmgr-root-entrypoint.sh"]
# CMD ["/opt/bitnami/scripts/postgresql-repmgr/run.sh"]
CMD ["/opt/bitnami/postgresql/bin/postgres", "-D", "/bitnami/postgresql/data"]
