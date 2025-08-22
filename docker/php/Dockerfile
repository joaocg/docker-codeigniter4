FROM php:8.3-apache

# Extensões necessárias
RUN docker-php-ext-install pdo pdo_mysql

# Habilita mod_rewrite
RUN a2enmod rewrite

# ================== ORACLE (OCI8 + PDO_OCI) ==================
# Pacotes necessários
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends unzip pkg-config build-essential autoconf; \
    (apt-get install -y --no-install-recommends libaio1 || apt-get install -y --no-install-recommends libaio1t64); \
    rm -rf /var/lib/apt/lists/*

# Zips que você tem em ./oracle/
ARG ORA_VER=21_13
ENV ORA_DIR=/opt/oracle/instantclient_${ORA_VER}
COPY ./oracle/instantclient-basic-linux.x64-21.13.0.0.0dbru.zip /tmp/
COPY ./oracle/instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip   /tmp/

# Extrai e registra no ldconfig (sem mv)
RUN set -eux; \
    mkdir -p /opt/oracle; \
    unzip -q /tmp/instantclient-basic-linux.x64-21.13.0.0.0dbru.zip -d /opt/oracle; \
    unzip -q /tmp/instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip   -d /opt/oracle; \
    test -d "${ORA_DIR}"; \
    echo "${ORA_DIR}" > /etc/ld.so.conf.d/oracle-instantclient.conf; \
    ldconfig; \
    rm -f /tmp/instantclient-*.zip

# Variáveis de ambiente úteis
ENV LD_LIBRARY_PATH=${ORA_DIR} \
    ORACLE_HOME=${ORA_DIR} \
    TNS_ADMIN=/opt/oracle/network/admin

# (opcional) pasta para tnsnames.ora
RUN mkdir -p /opt/oracle/network/admin

# OCI8 via PECL (driver nativo recomendado)
RUN set -eux; \
    echo "instantclient,${ORA_DIR}" | pecl install oci8; \
    docker-php-ext-enable oci8

# PDO_OCI (opcional)
RUN set -eux; \
    docker-php-source extract; \
    docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,${ORA_DIR},21.1; \
    docker-php-ext-install -j"$(nproc)" pdo_oci; \
    docker-php-source delete
# ================== /ORACLE ==================

# Docroot padrão (pode vir do build-arg)
ARG APACHE_DOCUMENT_ROOT=/var/www/html/public

# Vhost dedicado para o CI4 (mantido do seu)
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
