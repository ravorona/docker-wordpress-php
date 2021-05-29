FROM php:7.4-fpm

# Define composer env vars
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV COMPOSER_HOME /tmp
ENV COMPOSER_CACHE_DIR /var/cache
ENV COMPOSER_VERSION 2.0.14

# Update available package list from APT Repository
RUN apt-get update -y

# Install packages
RUN apt-get install -q -y --no-install-recommends \
  ca-certificates \
  curl \
  acl \
  cron \
  unzip \
  git \
  ghostscript \
  zlib1g-dev \
  libxml2-dev \
  libzip-dev \
  libicu-dev \
  libfreetype6-dev \
  libjpeg-dev \
  libmagickwand-dev \
  libpng-dev \
  libzip-dev \
  libmcrypt-dev \
  libyaml-dev

# Install PECL extensions
RUN pecl install yaml-2.0.4 \
  imagick-3.4.4

# PHP custom ini
RUN {\
  echo 'date.timezone=UTC'; \
  echo 'memory_limit=-1'; \
  echo 'opcache.enable_cli=1'; \
  } > $PHP_INI_DIR/php-cli.ini

RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
  } > $PHP_INI_DIR/opcache-recommended.ini

# Configure GD
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Configure ZIP
RUN docker-php-ext-configure zip --with-libzip

# Install PHP extensions
RUN docker-php-ext-install -j "$(nproc)" \
  gd \
  intl \
  exif \
  bcmath \
  pdo_mysql \
  mysqli \
  opcache \
  zip

# Enable PHP extensions
RUN docker-php-ext-enable yaml \
  imagick

# Composer
RUN curl --silent --fail --location --retry 3 --output /tmp/installer.php --url https://raw.githubusercontent.com/composer/getcomposer.org/cb19f2aa3aeaa2006c0cd69a7ef011eb31463067/web/installer \
  && php -r " \
    \$signature = '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5'; \
    \$hash = hash('sha384', file_get_contents('/tmp/installer.php')); \
    if (!hash_equals(\$signature, \$hash)) { \
      unlink('/tmp/installer.php'); \
      echo 'Integrity check failed, installer is either corrupt or worse.' . PHP_EOL; \
      exit(1); \
    }" \
  && php /tmp/installer.php --no-ansi --install-dir=/usr/bin --filename=composer --version=${COMPOSER_VERSION} \
  && composer --ansi --version --no-interaction \
  && rm -f /tmp/installer.php \
  && find /tmp -type d -exec chmod -v 1777 {} +

# Wordpress CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/local/bin/wp

# Cleaning
RUN apt-get purge -y --autoremove \
  && rm -rf /var/lib/apt/lists/*

# Set volume
VOLUME /var/www/html
