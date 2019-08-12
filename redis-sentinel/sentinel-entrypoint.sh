#!/bin/sh

sed -i "s/{{ SENTINEL_QUORUM }}/$SENTINEL_QUORUM/g" /redis/sentinel.conf
sed -i "s/{{ SENTINEL_DOWN_AFTER }}/$SENTINEL_DOWN_AFTER/g" /redis/sentinel.conf
sed -i "s/{{ SENTINEL_FAILOVER }}/$SENTINEL_FAILOVER/g" /redis/sentinel.conf
sed -i "s/{{ REDIS_MASTER_NAME }}/$REDIS_MASTER_NAME/g" /redis/sentinel.conf

redispass="/run/secrets/redis-proxy-password"
export REDIS_PASSWORD=$(cat "$redispass") 
sed -i "s/{{ REDIS_PASSWORD }}/$REDIS_PASSWORD/g" /redis/sentinel.conf

# sentinel_ips=$(drill tasks.$REDIS_SENTINEL_NAME | grep tasks.$REDIS_SENTINEL_NAME | tail -n +2 | awk '{print $5}')

# for ip in $sentinel_ips; do
master_info=$(redis-cli -h redis-sentinel -p 26379 -a $REDIS_PASSWORD sentinel get-master-addr-by-name $REDIS_MASTER_NAME)
if [ "$master_info" ]; then
    REDIS_IP=$(echo $master_info | awk '{print $1}')
    break
fi
# done

if [ ! "$master_info" ]; then
    until [ "$(redis-cli -h $REDIS_IP -p 6379 -a $REDIS_PASSWORD ping)" = "PONG" ]; do
        echo "$REDIS_IP is unavailable - sleeping"
        sleep 1
    done
fi

sed -i "s/{{ REDIS_IP }}/$REDIS_MASTER_IP/g" /redis/sentinel.conf
redis-server /redis/sentinel.conf --sentinel
