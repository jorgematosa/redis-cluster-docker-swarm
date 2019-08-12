#!/bin/sh
redispass="/run/secrets/redis-proxy-password"
export REDIS_PASSWORD=$(cat "$redispass") 
sed -i "s/{{ REDIS_PASSWORD }}/$REDIS_PASSWORD/g" /redis/redis.conf

until [ "$(redis-cli -h $REDIS_SENTINEL_IP -p $REDIS_SENTINEL_PORT ping)" = "PONG" ]; do
	echo "$REDIS_SENTINEL_IP is unavailable - sleeping"
	sleep 1
done

master_info=$(redis-cli -h $REDIS_SENTINEL_IP -p $REDIS_SENTINEL_PORT sentinel get-master-addr-by-name $REDIS_MASTER_NAME)

until [ "$master_info" ]; do
	echo "$REDIS_MASTER_NAME not found - sleeping"
	sleep 1
	master_info=$(redis-cli -h $REDIS_SENTINEL_IP -p $REDIS_SENTINEL_PORT sentinel get-master-addr-by-name $REDIS_MASTER_NAME)
done

master_ip=$(echo $master_info | awk '{print $1}')
master_port=$(echo $master_info | awk '{print $2}')

echo "Slave ip found: $SLAVE_IP"

sed -i "s/{{ SLAVE_ANNOUNCE_IP }}/$SLAVE_IP/g" /redis/redis.conf
sed -i "s/{{ TOTAL_ENTRIES_TO_BCKP }}/$ENTRIES_BEFORE_SAVE/g" /redis/redis.conf
echo "Total entries to backup: $ENTRIES_BEFORE_SAVE"

# allow the container to be started with `--user`
if [ "$1" = 'redis-server' -a "$(id -u)" = '0' ]; then
	find . \! -user redis -exec chown redis '{}' +
	exec su-exec redis "$0" "$@"
fi

redis-server /redis/redis.conf --slaveof $REDIS_MASTER_IP $master_port
