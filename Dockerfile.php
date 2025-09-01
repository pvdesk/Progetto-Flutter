FROM php:8.2-apache

# Abilita mod_rewrite (utile per framework/router)
RUN a2enmod rewrite

# Estensioni PHP fondamentali per MySQL e altro
RUN docker-php-ext-install pdo pdo_mysql mysqli

# (opzionale) set timezone PHP
RUN printf "date.timezone=%s\n" "Europe/Rome" > /usr/local/etc/php/conf.d/timezone.ini
