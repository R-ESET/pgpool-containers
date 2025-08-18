FROM docker.io/bitnami/minideb:bookworm

ARG DOWNLOADS_URL="downloads.bitnami.com/files/stacksmith"
ARG TARGETARCH

ENV HOME="/" \
    OS_ARCH="${TARGETARCH:-amd64}" \
    OS_FLAVOUR="debian-12" \
    OS_NAME="linux"

SHELL ["/bin/bash", "-o", "errexit", "-o", "nounset", "-o", "pipefail", "-c"]

# Install required packages (including supervisor)
RUN install_packages ca-certificates curl procps locales supervisor

# Download PostgreSQL + repmgr binaries (adjust version if needed)
RUN set -eux; \
  mkdir -p /tmp/bitnami/pkg/cache/ && cd /tmp/bitnami/pkg/cache/; \
  COMPONENTS=( \
    "postgresql-17.5.0-11-linux-${OS_ARCH}-debian-12" \
    "postgresql-repmgr-17.5.0-11-linux-${OS_ARCH}-debian-12" \
  ); \
  for COMPONENT in "${COMPONENTS[@]}"; do \
    curl -SsLf "https://${DOWNLOADS_URL}/${COMPONENT}.tar.gz" -O; \
    curl -SsLf "https://${DOWNLOADS_URL}/${COMPONENT}.tar.gz.sha256" -O; \
    sha256sum -c "${COMPONENT}.tar.gz.sha256"; \
    tar -zxf "${COMPONENT}.tar.gz" -C /opt/bitnami --strip-components=2 --no-same-owner; \
    rm -f "${COMPONENT}.tar.gz" "${COMPONENT}.tar.gz.sha256"; \
  done

# Locale setup
RUN update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX && \
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales && \
    echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
    echo 'en_GB.UTF-8 UTF-8' >> /etc/locale.gen

# Ensure proper dirs and permissions
RUN mkdir -p /bitnami /opt/bitnami/repmgr/tmp /opt/bitnami/postgresql/logs \
 && chown -R 1001:1001 /opt/bitnami /bitnami /tmp \
 && chmod -R 775 /opt/bitnami/repmgr/tmp

# Hardcode repmgrd PID file in /tmp
RUN echo "repmgrd_pid_file='/tmp/repmgrd.pid'" \
    >> /opt/bitnami/repmgr/conf/repmgr.conf

# Supervisord configuration
COPY <<'EOF' /etc/supervisor/conf.d/supervisord.conf
[supervisord]
nodaemon=true
user=root
logfile=/var/log/supervisord.log
pidfile=/var/run/supervisord.pid

[program:postgresql]
command=/opt/bitnami/postgresql/bin/postgres -D /bitnami/postgresql/data -c config_file=/opt/bitnami/postgresql/conf/postgresql.conf
autostart=true
autorestart=true
user=1001
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr

[program:repmgrd]
command=/opt/bitnami/repmgr/bin/repmgrd --config-file=/opt/bitnami/repmgr/conf/repmgr.conf --daemonize=false
autostart=true
autorestart=true
user=1001
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stderr
EOF

EXPOSE 5432

# Run under supervisord
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
