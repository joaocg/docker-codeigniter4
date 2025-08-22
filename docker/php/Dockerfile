FROM php:8.3-apache

# ------------------------------------------------------------
# Extensões básicas
# ------------------------------------------------------------
# PDO + MySQL
RUN docker-php-ext-install pdo pdo_mysql
# MySQLi (contra mysqlnd)
RUN set -eux; \
    docker-php-ext-configure mysqli --with-mysqli=mysqlnd; \
    docker-php-ext-install -j"$(nproc)" mysqli

# Habilita mod_rewrite
RUN a2enmod rewrite

# ------------------------------------------------------------
# Oracle (OCI8 + PDO_OCI) e INTL
# - dependências de runtime (libaio, libnsl) e build (autoconf, build-essential)
# - libicu-dev para intl
# ------------------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends unzip pkg-config build-essential autoconf libicu-dev; \
    (apt-get install -y --no-install-recommends libaio1  || apt-get install -y --no-install-recommends libaio1t64); \
    (apt-get install -y --no-install-recommends libnsl   || apt-get install -y --no-install-recommends libnsl2); \
    # Compat: algumas libs ainda procuram libnsl.so.1 em Debian recente
    if [ ! -e /usr/lib/x86_64-linux-gnu/libnsl.so.1 ] && [ -e /usr/lib/x86_64-linux-gnu/libnsl.so.2 ]; then ln -s /usr/lib/x86_64-linux-gnu/libnsl.so.2 /usr/lib/x86_64-linux-gnu/libnsl.so.1; fi; \
    rm -rf /var/lib/apt/lists/*

# Caminho do Instant Client (21.13)
ARG ORA_VER=21_13
ENV ORA_DIR=/opt/oracle/instantclient_${ORA_VER}
COPY ./oracle/instantclient-basic-linux.x64-21.13.0.0.0dbru.zip /tmp/
COPY ./oracle/instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip   /tmp/

# Extrai os zips e registra no ldconfig (sem mv)
RUN set -eux; \
    mkdir -p /opt/oracle; \
    unzip -q /tmp/instantclient-basic-linux.x64-21.13.0.0.0dbru.zip -d /opt/oracle; \
    unzip -q /tmp/instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip   -d /opt/oracle; \
    test -d "${ORA_DIR}"; \
    echo "${ORA_DIR}" > /etc/ld.so.conf.d/oracle-instantclient.conf; \
    ldconfig; \
    rm -f /tmp/instantclient-*.zip; \
    # Diagnóstico útil nos logs de build
    ldconfig -p | grep -E "libclntsh|libnsl|libaio" || true

# Variáveis de ambiente úteis para o Oracle
ENV LD_LIBRARY_PATH=${ORA_DIR} \
    ORACLE_HOME=${ORA_DIR} \
    TNS_ADMIN=/opt/oracle/network/admin

# (opcional) pasta para tnsnames.ora
RUN mkdir -p /opt/oracle/network/admin

# OCI8 via PECL (força versão compatível e cai para a mais recente se necessário)
# + teste em build para garantir que carregou
RUN set -eux; \
    printf "instantclient,%s\n" "${ORA_DIR}" | pecl install oci8-3.3.0 || \
    (printf "instantclient,%s\n" "${ORA_DIR}" | pecl install oci8); \
    docker-php-ext-enable oci8; \
    echo "extension=oci8" > /usr/local/etc/php/conf.d/oci8.ini; \
    php -m | grep -i oci8

# (Opcional) PDO_OCI
RUN set -eux; \
    docker-php-source extract; \
    docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,${ORA_DIR},21.1; \
    docker-php-ext-install -j"$(nproc)" pdo_oci; \
    docker-php-source delete

# INTL
RUN set -eux; \
    docker-php-ext-configure intl; \
    docker-php-ext-install -j"$(nproc)" intl

# ------------------------------------------------------------
# VHost do CodeIgniter 4 (docroot em /public)  **(MANTIDO)**
# ------------------------------------------------------------
ARG APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN set -eux; \
    echo "<VirtualHost *:80>\n\
    DocumentRoot ${APACHE_DOCUMENT_ROOT}\n\
    <Directory ${APACHE_DOCUMENT_ROOT}>\n\
        AllowOverride All\n\
        Require all granted\n\
        Options FollowSymLinks\n\
    </Directory>\n\
    ErrorLog \${APACHE_LOG_DIR}/error.log\n\
    CustomLog \${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>" > /etc/apache2/sites-available/ci4.conf && \
    a2dissite 000-default && \
    a2ensite ci4

WORKDIR /var/www/html
