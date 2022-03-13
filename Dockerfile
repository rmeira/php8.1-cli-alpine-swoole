FROM php:8.1-cli-alpine3.15

ENV ACCEPT_EULA=Y

# Install prerequisites required for tools and extensions installed later on.
RUN apk add --update bash gnupg libpng-dev libzip-dev su-exec unzip supervisor

# Install prerequisites for the sqlsrv and pdo_sqlsrv PHP extensions.
RUN curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.7.1.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.7.1.1-1_amd64.apk \
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/msodbcsql17_17.7.1.1-1_amd64.sig \
    && curl -O https://download.microsoft.com/download/e/4/e/e4e67866-dffd-428c-aac7-8d28ddafb39b/mssql-tools_17.7.1.1-1_amd64.sig \
    && curl https://packages.microsoft.com/keys/microsoft.asc  | gpg --import - \
    && gpg --verify msodbcsql17_17.7.1.1-1_amd64.sig msodbcsql17_17.7.1.1-1_amd64.apk \
    && gpg --verify mssql-tools_17.7.1.1-1_amd64.sig mssql-tools_17.7.1.1-1_amd64.apk \
    && apk add --allow-untrusted msodbcsql17_17.7.1.1-1_amd64.apk mssql-tools_17.7.1.1-1_amd64.apk \
    && rm *.apk *.sig

# Retrieve the script used to install PHP extensions from the source container.
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/install-php-extensions

# Install required PHP extensions and all their prerequisites available via apt.
RUN chmod uga+x /usr/bin/install-php-extensions \
    && sync \
    && install-php-extensions bcmath ds exif gd intl opcache pcntl pcov pdo_sqlsrv redis sqlsrv zip swoole mysqli pdo_mysql ext-ldap ldap

# Downloading composer and marking it as executable.
RUN curl -o /usr/local/bin/composer https://getcomposer.org/composer-stable.phar \
    && chmod +x /usr/local/bin/composer

# Remove HTML folder inside /var/www
RUN rm -rf /var/www/html

# Setting the work directory.
WORKDIR /var/www

# COPY PHP CONFIGS
COPY ./php/php.ini /usr/local/etc/php/php.ini

# COPY CRONTAB CONFIGS
COPY ./crontabs/cron /etc/cron
RUN chmod 0644 /etc/cron && crontab /etc/cron

# COPY SUPERVISOR CONFIG
COPY ./supervisor/supervisord.conf /etc/supervisord.conf

# COPY SHELLSCRIPT
COPY ./scripts/init.sh /scripts/init.sh
RUN chmod +x /scripts/init.sh

EXPOSE 8000

ENTRYPOINT ["/scripts/init.sh"]