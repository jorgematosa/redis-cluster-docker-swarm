#!/bin/sh
set -e

redispass="/run/secrets/redis-proxy-password"
export REDIS_PASSWORD=$(cat "$redispass") 
sed -i "s/{{ REDIS_PASSWORD }}/$REDIS_PASSWORD/g" /redis/redis.conf
sed -i "s/{{ TOTAL_ENTRIES_TO_BCKP }}/$ENTRIES_BEFORE_SAVE/g" /redis/redis.conf
echo "Total entries to backup: $ENTRIES_BEFORE_SAVE"

# first arg is `-f` or `--some-option`
# or first arg is `something.conf`
if [ "${1#-}" != "$1" ] || [ "${1%.conf}" != "$1" ]; then
	set -- redis-server "$@"
fi

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	find . \! -user redis -exec chown redis '{}' +
	exec su-exec redis "$0" "$@"
fi

redis-server /redis/redis.conf
