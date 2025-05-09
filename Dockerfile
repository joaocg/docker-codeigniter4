FROM php:8.2-apache

# Instala pacotes de dependência
RUN apt-get update && apt-get install -y \
    unzip \
    libaio1 \
    libicu-dev \
    git \
    curl \
    build-essential

# Copia os zips do Oracle para dentro da imagem
COPY oracle/instantclient-basic-linux.x64-21.13.0.0.0dbru.zip /tmp/
COPY oracle/instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip /tmp/

# Descompacta e move o Oracle Instant Client
RUN unzip /tmp/instantclient-basic-linux.x64-21.13.0.0.0dbru.zip -d /opt \
    && unzip /tmp/instantclient-sdk-linux.x64-21.13.0.0.0dbru.zip -d /opt \
    && ln -sf /opt/instantclient_21_13 /opt/oracle \
    && ln -sf /opt/oracle/libclntsh.so.21.1 /opt/oracle/libclntsh.so \
    && echo /opt/oracle > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

# Instala o PDO Oracle
ENV LD_LIBRARY_PATH=/opt/oracle
ENV ORACLE_HOME=/opt/oracle
RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle \
    && docker-php-ext-install pdo_oci intl mysqli pdo_mysql

# Ativa mod_rewrite do Apache
RUN a2enmod rewrite

# Define o DocumentRoot do Apache para a pasta 'public' do CodeIgniter
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf

# Instala o Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer --version
