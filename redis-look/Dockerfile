FROM redis:5-alpine

ENV REDIS_SENTINEL_IP redis-sentinel
ENV REDIS_MASTER_NAME redismaster
ENV REDIS_SENTINEL_PORT 26379

COPY entrypoint.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /redis
RUN chown redis:redis /redis

COPY redis.conf .
RUN chown redis:redis /redis/redis.conf
USER redis

EXPOSE 26379

ENTRYPOINT ["entrypoint.sh"]
