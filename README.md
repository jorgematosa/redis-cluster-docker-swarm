This work is based on the original work of thomasjpfan presented in the following repo: https://github.com/thomasjpfan/redis-cluster-docker-swarm

A few modifications are made to change the generated ips to service name and ip auto discovery.

# Redis Cluster Cache for Docker Swarm

Quick and dirty Redis cluster taking advantage of Redis Sentinel for automatic failover. Persistence is turned on by default.

## Usage

0. Setup docker swarm

1. Create an overlay network called redis and create a new secret called redis-proxy-password in swarm

2. Build the images:

```bash
bash scripts/build.sh latest
```

3. Modify scripts/docker-compose.yml to how you want to deploy the stack.
4. Run `scripts/bootstrap.sh`.

```bash
bash scripts/bootstrap.sh latest
```

5. Connect to with redis-cli

```bash
redis-cli -h HOSTNAME -p 6379
```

## Details

A docker service called `redis-zero` is created to serve as the initial master for the redis sentinels to setup. The `redis-look` instances watches the redis sentinels for a master, and connects to `redis-zero` once a master has been decided. Once the dust has settled, scale the `redis-zero` instance and wait for failover to take over so a new redis-master will take over. Use `redis-utils` to reset sentinels so that its metadata is accurate with the correct state.

```yaml
version: '3.6'

services:
  redis-zero:
    image: redis-zero:latest
    deploy:
      replicas: 1
    volumes:
      - redis-master:/data/
    networks:
      - redis
    environment:
      - ENTRIES_BEFORE_SAVE=1
    secrets:
      - redis-proxy-password


  redis-sentinel:
    image: redis-sentinel:${TAG:-latest}
    environment:
      - REDIS_IP=redis-zero
      - REDIS_MASTER_NAME=redismaster
      - REDIS_MASTER_IP=redis-zero
    ports:
      - 26379:26379
    deploy:
      replicas: 3
    networks:
      - redis
    secrets:
      - redis-proxy-password
      
  redis1:
    image: redis-look:${TAG:-latest}
    environment:
      - REDIS_SENTINEL_IP=redis-sentinel
      - REDIS_MASTER_NAME=redismaster
      - REDIS_MASTER_IP=redis-zero
      - REDIS_SENTINEL_PORT=26379
      - SLAVE_IP=redis1
      - ENTRIES_BEFORE_SAVE=1
    volumes:
      - redis-data1:/data
    deploy:
      replicas: 1
    networks:
      - redis
    secrets:
      - redis-proxy-password
  redis2:
    image: redis-look:${TAG:-latest}
    environment:
      - REDIS_SENTINEL_IP=redis-sentinel
      - REDIS_MASTER_NAME=redismaster
      - REDIS_MASTER_IP=redis-zero
      - REDIS_SENTINEL_PORT=26379
      - SLAVE_IP=redis2
      - ENTRIES_BEFORE_SAVE=1
    volumes:
      - redis-data2:/data
    deploy:
      replicas: 1
    networks:
      - redis
    secrets:
      - redis-proxy-password
  redis3:
    image: redis-look:${TAG:-latest}
    environment:
      - REDIS_SENTINEL_IP=redis-sentinel
      - REDIS_MASTER_NAME=redismaster
      - REDIS_MASTER_IP=redis-zero
      - REDIS_SENTINEL_PORT=26379
      - SLAVE_IP=redis3
      - ENTRIES_BEFORE_SAVE=1
    volumes:
      - redis-data3:/data
    deploy:
      replicas: 1
    networks:
      - redis
    secrets:
      - redis-proxy-password
  proxy:
    image: haproxy-redis:${TAG:-latest}
    depends_on:
      - redis-sentinel
      - redis1
      - redis2
      - redis3
    deploy:
      replicas: 3
    ports:
      - '9001:9000'
      - '6379:6379'
    environment:
      - REDIS_HOSTS=redis-zero,redis1,redis2,redis3
    networks:
      - redis
    secrets:
      - redis-proxy-password

networks:
  redis:
    external: true

volumes:
  redis-master:
    driver: local
  redis-data1:
    driver: local
  redis-data2:
    driver: local
  redis-data3:
    driver: local

secrets:
  redis-proxy-password:
    external: true
```

## Import a backup

To import a backup, put the dump.rdb file located in Redis server /data folder in the host and map the redis-zero volume below.

```yaml
version: '3.6'

services:

  redis-zero:
    image: redis-zero:latest
    deploy:
      replicas: 1
    volumes:
      - redis-master:/data/
    environment:
      - ENTRIES_BEFORE_SAVE=1
    networks:
      - default
```