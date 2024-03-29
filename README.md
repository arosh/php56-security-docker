# php56-security-docker

This is a fork of [php:5.6.40-apache-stretch](https://github.com/docker-library/php/tree/ecd7dcc69c76f0e582c2274ecb90dcb7264e245c/5.6/stretch/apache), the official container image of [PHP](https://hub.docker.com/_/php/).

As you know, [PHP 5.6 reached EOL on December 31, 2018](https://www.php.net/eol.php). Distributions that provide long-term support, such as RHEL, provide extended support for the packages they include according to their own support policies. The PHP binaries in the container images in this repository are built from [remicollet/php-src-security](https://github.com/remicollet/php-src-security/tree/PHP-5.6-security-backports-openssl11), which includes security fixes distributed by [Remi's RPM repository](https://rpms.remirepo.net/enterprise/7/php56/x86_64/repoview/).

Other than that, there is no difference in terms of usage. You can refer to [the description of the original container image](https://hub.docker.com/_/php/) for details.
