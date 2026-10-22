# php56-security-docker

This is a container image that mimics the layout of [php:5.6.40-apache-stretch](https://github.com/docker-library/php/tree/ecd7dcc69c76f0e582c2274ecb90dcb7264e245c/5.6/stretch/apache), the official container image of [PHP](https://hub.docker.com/_/php/), so that it can be used as a drop-in parent image.

As you know, [PHP 5.6 reached EOL on December 31, 2018](https://www.php.net/eol.php). The PHP binaries in this image are the packages distributed by [deb.sury.org](https://deb.sury.org/) (`php5.6-*`, `libapache2-mod-php5.6`), which keep receiving security backports. The base image is `debian:trixie-slim`.

## Compatibility with the official image

- `PHP_INI_DIR` is `/usr/local/etc/php`, with `php.ini-development` / `php.ini-production`. Both the CLI and mod_php read their configuration from there (via `PHPRC` / `PHP_INI_SCAN_DIR`), not from `/etc/php/5.6`.
- Extensions that the official image compiles statically (curl, dom, mbstring, mysqlnd, sqlite3, xml, ...) are loaded through `$PHP_INI_DIR/conf.d/sury-*.ini`. `pcntl` is additionally available.
- `docker-php-ext-enable` works, e.g. `docker-php-ext-enable opcache.so` (opcache is not enabled by default, as in the official image).
- Apache uses `mpm_prefork` with mod_php, and `CMD ["apache2-foreground"]`, `WORKDIR /var/www/html` are unchanged.

## Differences

- `docker-php-source`, `docker-php-ext-install` and `docker-php-ext-configure` are no longer provided because PHP is not built from source. Install extensions from the sury repository (already configured in the image) instead, and enable them with `docker-php-ext-enable` or a file in `$PHP_INI_DIR/conf.d`:

  ```dockerfile
  RUN apt-get update && apt-get install -y --no-install-recommends php5.6-gd php5.6-mysql \
    && rm -rf /var/lib/apt/lists/* \
    && echo 'extension=mysqli.so' > "$PHP_INI_DIR/conf.d/mysqli.ini"
  ```

- Extension packages installed with apt add their `.ini` files under `/etc/php/5.6/mods-available`, which is not scanned; create the `.ini` in `$PHP_INI_DIR/conf.d` as above.

## Tests

`tests/smoke.sh IMAGE` checks `php -v`, the loaded modules, `phpinfo()` served by Apache and a downstream image built like [icpc-jag/jag-ansible's pukiwiki image](https://github.com/icpc-jag/jag-ansible/blob/master/roles/web/files/pukiwiki/Dockerfile).

```sh
docker build -t php56-security-docker 5.6/apache
tests/smoke.sh php56-security-docker
```
