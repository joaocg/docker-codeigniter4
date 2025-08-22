FROM --platform=linux/amd64 php:8.2-apache-bookworm
ARG TZ=America/Sao_Paulo
ENV TZ=${TZ}
WORKDIR /var/www/html

RUN apt-get update && apt-get install -y --no-install-recommends \
    libicu-dev libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libonig-dev pkg-config git curl zip unzip \
    libaio1 libaio-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" intl zip gd mbstring bcmath exif sockets pdo_mysql mysqli opcache \
 && a2enmod rewrite headers \
 && rm -rf /var/lib/apt/lists/*


ARG ORACLE_IC_VERSION=23_9
RUN mkdir -p /opt/oracle \
    && curl -fsSL -o /opt/oracle/instantclient-basiclite.zip https://download.oracle.com/otn_software/linux/instantclient/instantclient-basiclite-linuxx64.zip \
    && curl -fsSL -o /opt/oracle/instantclient-sdk.zip https://download.oracle.com/otn_software/linux/instantclient/instantclient-sdk-linuxx64.zip \
    && unzip -q -o /opt/oracle/instantclient-basiclite.zip -d /opt/oracle/ \
    && unzip -q -o /opt/oracle/instantclient-sdk.zip -d /opt/oracle/ \
    && rm /opt/oracle/instantclient-basiclite.zip \
    && rm /opt/oracle/instantclient-sdk.zip \
    && ln -s /opt/oracle/instantclient_${ORACLE_IC_VERSION} /opt/oracle/instantclient \
    && echo "/opt/oracle/instantclient" > /etc/ld.so.conf.d/oracle-instantclient.conf \
    && ldconfig

RUN echo 'instantclient,/opt/oracle/instantclient' | pecl install oci8 \
    && echo "extension=oci8.so" > /usr/local/etc/php/conf.d/oci8.ini

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/000-default.conf \
    && sed -ri -e 's!<Directory /var/www/>!<Directory ${APACHE_DOCUMENT_ROOT}/>!g' /etc/apache2/apache2.conf \
    && sed -ri -e 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=3 CMD php -m | grep -q oci8 || exit 1
