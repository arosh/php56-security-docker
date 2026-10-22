#!/bin/bash
# usage: tests/smoke.sh IMAGE
# Verifies PHP via CLI and Apache (mod_php), then builds a downstream image the way
# icpc-jag/jag-ansible does (tests/downstream/Dockerfile) and verifies it too.
set -euo pipefail

image="${1:?usage: $0 IMAGE}"
here="$(cd "$(dirname "$0")" && pwd)"
containers=()
child="php56-smoke-downstream:$$"

cleanup() {
	if [ "${#containers[@]}" -gt 0 ]; then
		docker rm -f "${containers[@]}" > /dev/null 2>&1 || true
	fi
	docker rmi "$child" > /dev/null 2>&1 || true
}
trap cleanup EXIT

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

# start IMAGE -> prints the base URL once Apache answers
start() {
	local id port
	id="$(docker run -d -p 127.0.0.1::80 -v "$here/phpinfo.php:/var/www/html/phpinfo.php:ro" "$1")"
	containers+=("$id")
	port="$(docker port "$id" 80/tcp | head -n1 | sed 's/.*://')"
	for _ in $(seq 1 30); do
		if curl -fsS "http://127.0.0.1:$port/phpinfo.php" > /dev/null 2>&1; then
			echo "http://127.0.0.1:$port"
			return 0
		fi
		sleep 1
	done
	docker logs "$id" >&2
	fail "Apache did not answer for $1"
}

echo "== CLI ($image)"
docker run --rm "$image" php -v | grep -q '^PHP 5\.6\.40' || fail "php -v"
modules="$(docker run --rm "$image" php -m)"
for m in ctype curl dom fileinfo ftp iconv json mbstring mysqlnd openssl pdo_sqlite posix readline sqlite3 tokenizer xml zlib; do
	grep -qx "$m" <<< "$modules" || fail "module $m is not loaded"
done

# prints phpinfo() output served by Apache for the given image
check_web() {
	local url body
	url="$(start "$1")"
	body="$(curl -fsS "$url/phpinfo.php")"
	grep -q 'PHP Version => 5\.6\.40\|PHP Version 5\.6\.40' <<< "$body" || fail "phpinfo: version ($1)"
	grep -q 'Apache 2.0 Handler' <<< "$body" || fail "phpinfo: not served by mod_php ($1)"
	echo "$body"
}

echo "== Apache ($image)"
body="$(check_web "$image")"
if grep -q 'Zend OPcache' <<< "$body"; then fail "opcache should be disabled by default"; fi
grep -q '/usr/local/etc/php/conf.d' <<< "$body" || fail "mod_php ignores PHP_INI_SCAN_DIR"

echo "== Downstream ($image)"
docker build -q --build-arg "BASE_IMAGE=$image" -t "$child" "$here/downstream" > /dev/null
body="$(check_web "$child")"
grep -q 'Zend OPcache' <<< "$body" || fail "opcache not enabled in downstream image"
grep -q '/usr/local/etc/php/php.ini' <<< "$body" || fail "downstream php.ini not loaded"
docker run --rm "$child" php -r 'exit(ini_get("expose_php") ? 1 : 0);' || fail "expose_php not turned off"
if docker run --rm "$child" php -v 2>&1 | grep -qi 'warning'; then
	fail "php -v prints warnings in the downstream image"
fi

echo "OK"
