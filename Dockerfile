FROM php:8.2-apache

# Instalar dependências necessárias
RUN apt-get update && apt-get install -y \
    libicu-dev \
    unzip \
    git \
    curl \
    && docker-php-ext-install intl

# Ativar mod_rewrite (necessário pro CodeIgniter)
RUN a2enmod rewrite

# Instalar o Composer globalmente
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Verifica se o Composer foi instalado corretamente
RUN composer --version
