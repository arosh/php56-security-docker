FROM debian:trixie-slim

# prevent Debian's own PHP packages from being installed (PHP comes from deb.sury.org)
# https://github.com/docker-library/php/pull/542
RUN set -eux; \
	{ \
		echo 'Package: php*'; \
		echo 'Pin: release o=Debian'; \
		echo 'Pin-Priority: -1'; \
	} > /etc/apt/preferences.d/no-debian-php

ENV PHP_VERSION 5.6.40
ENV PHP_INI_DIR /usr/local/etc/php
# mod_php and the CLI read their configuration from $PHP_INI_DIR instead of /etc/php/5.6/*
ENV PHPRC $PHP_INI_DIR
ENV PHP_INI_SCAN_DIR $PHP_INI_DIR/conf.d

# extensions that were compiled statically into the previous source-built image
ENV PHP_BUILTIN_EXTS "ctype curl dom fileinfo ftp iconv json mbstring mysqlnd pdo pdo_sqlite phar posix readline simplexml sqlite3 tokenizer xml xmlreader xmlwriter"

RUN set -eux; \
	apt-get update; \
# binutils provides readelf, which docker-php-ext-enable needs to detect zend extensions such as opcache
	apt-get install -y --no-install-recommends binutils ca-certificates curl; \
	curl -fsSL -o /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg; \
	. /etc/os-release; \
	echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $VERSION_CODENAME main" > /etc/apt/sources.list.d/php.list; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		apache2 \
		libapache2-mod-php5.6 \
		php5.6-cli \
		php5.6-curl \
		php5.6-mbstring \
		php5.6-mysql \
		php5.6-readline \
		php5.6-sqlite3 \
		php5.6-xml \
	; \
	rm -rf /var/lib/apt/lists/*

# Debian's configuration under /etc/php is replaced by $PHP_INI_DIR (no php.ini by default, like the official image)
RUN set -eux; \
	mkdir -p "$PHP_INI_DIR/conf.d"; \
	cp -v /usr/lib/php/5.6/php.ini-* "$PHP_INI_DIR/"; \
	rm -f /etc/php/5.6/cli/php.ini /etc/php/5.6/apache2/php.ini; \
	for ext in $PHP_BUILTIN_EXTS; do \
		if [ -f "/etc/php/5.6/mods-available/$ext.ini" ]; then \
			echo "extension=$ext.so" > "$PHP_INI_DIR/conf.d/sury-$ext.ini"; \
		fi; \
	done; \
	ls "$PHP_INI_DIR/conf.d"

ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars

RUN set -eux; \
	\
# generically convert lines like
#   export APACHE_RUN_USER=www-data
# into
#   : ${APACHE_RUN_USER:=www-data}
#   export APACHE_RUN_USER
# so that they can be overridden at runtime ("-e APACHE_RUN_USER=...")
	sed -ri 's/^export ([^=]+)=(.*)$/: ${\1:=\2}\nexport \1/' "$APACHE_ENVVARS"; \
	\
# setup directories and permissions
	. "$APACHE_ENVVARS"; \
	for dir in \
		"$APACHE_LOCK_DIR" \
		"$APACHE_RUN_DIR" \
		"$APACHE_LOG_DIR" \
		/var/www/html \
	; do \
		rm -rvf "$dir"; \
		mkdir -p "$dir"; \
		chown "$APACHE_RUN_USER:$APACHE_RUN_GROUP" "$dir"; \
# allow running as an arbitrary user (https://github.com/docker-library/php/issues/743)
		chmod 777 "$dir"; \
	done; \
	\
# logs should go to stdout / stderr
	ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log"; \
	ln -sfT /dev/stdout "$APACHE_LOG_DIR/access.log"; \
	ln -sfT /dev/stdout "$APACHE_LOG_DIR/other_vhosts_access.log"; \
	chown -R --no-dereference "$APACHE_RUN_USER:$APACHE_RUN_GROUP" "$APACHE_LOG_DIR"

# Apache + PHP requires preforking Apache for best results
RUN a2dismod mpm_event && a2enmod mpm_prefork && a2enmod php5.6

# PHP files should be handled by PHP, and should be preferred over any other file type
RUN { \
		echo '<FilesMatch \.php$>'; \
		echo '\tSetHandler application/x-httpd-php'; \
		echo '</FilesMatch>'; \
		echo; \
		echo 'DirectoryIndex disabled'; \
		echo 'DirectoryIndex index.php index.html'; \
		echo; \
		echo '<Directory /var/www/>'; \
		echo '\tOptions -Indexes'; \
		echo '\tAllowOverride All'; \
		echo '</Directory>'; \
	} | tee "$APACHE_CONFDIR/conf-available/docker-php.conf" \
	&& a2enconf docker-php

COPY docker-php-ext-enable docker-php-entrypoint /usr/local/bin/

ENTRYPOINT ["docker-php-entrypoint"]

COPY apache2-foreground /usr/local/bin/
WORKDIR /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
