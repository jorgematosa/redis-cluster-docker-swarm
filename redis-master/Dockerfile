FROM redis:5-alpine

# LABEL version="1.0.2"

# ENV REDIS_SENTINEL_IP redis-sentinel
# ENV REDIS_MASTER_NAME redismaster
# ENV REDIS_SENTINEL_PORT 26379

COPY entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh

# RUN mkdir /redis
# RUN chmod -R 777 /redis
RUN mkdir /redis && chown redis:redis /redis
COPY redis.conf /redis/redis.conf
RUN chown redis:redis /redis/redis.conf

ENTRYPOINT ["entrypoint.sh"]
# CMD [ "redis-server", "/redis/redis.conf" ]