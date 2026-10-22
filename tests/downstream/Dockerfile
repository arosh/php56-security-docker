ARG BASE_IMAGE
FROM ${BASE_IMAGE}

# mirrors https://github.com/icpc-jag/jag-ansible/blob/master/roles/web/files/pukiwiki/Dockerfile
RUN apt-get update && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
     libapache2-mod-rpaf a2ps \
  && rm -rf /var/lib/apt/lists/*
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
        && sed -ri 's/^expose_php = (.*)$/expose_php = Off/' "$PHP_INI_DIR/php.ini" \
        && sed -ri '$a session.upload_progress.enabled = 0' "$PHP_INI_DIR/php.ini" \
        && docker-php-ext-enable opcache.so \
        && a2disconf other-vhosts-access-log serve-cgi-bin \
        && a2dismod reqtimeout status
