#!/bin/sh

set -ex

echo "=> Creating HAProxy Configuration Folder"
mkdir -p /etc/haproxy

adminpass="/run/secrets/redis-proxy-password"

export ADMIN_PASSWORD=$(cat "$adminpass") 

echo "=> Writing HAProxy Configuration File"
tee /etc/haproxy/haproxy.cfg <<EOF
# userlist TrustedUsers
# user admin insecure-password manage
defaults
  mode tcp
  timeout connect 3s
  timeout server 6s
  timeout client 6s
listen stats
  mode http
  bind :9000
  stats enable
  stats hide-version
  stats realm Haproxy\ Statistics
  stats uri /haproxy_stats
  stats auth redis:$ADMIN_PASSWORD
frontend ft_redis
  mode tcp
  bind *:6379
  # acl acl_redis http_auth(trusted_users)
  # use_backend bk_redis if acl_redis
  default_backend bk_redis
backend bk_redis
  mode tcp
  option tcplog
  option tcp-check
  #uncomment these lines if you have basic auth
  tcp-check send AUTH\ $ADMIN_PASSWORD\r\n
  tcp-check expect string +OK
  # acl AuthOkay_bk_redis http_auth(trusted_users)
  # http-request auth if !AuthOkay_bk_redis
  # acl AuthOkay_trusted_users http_auth(trusted_users)
  # http-request auth realm trusted_users if !AuthOkay_trusted_users
  # acl is_auth_ok http_auth(TrustedUsers)
  # http-request auth realm MySite if !is_internal !is_auth_ok
  tcp-check send PING\r\n
  tcp-check expect string +PONG
  tcp-check send info\ replication\r\n
  tcp-check expect string role:master
  tcp-check send QUIT\r\n
  tcp-check expect string +OK
EOF

echo "=> Adding Redis Nodes to Health Check"
COUNT=1

for i in $(echo $REDIS_HOSTS | sed "s/,/ /g")
do
    # call your procedure/other scripts here below
    echo "  server redis-backend-$COUNT $i:6379 maxconn 1024 check inter 1s" >> /etc/haproxy/haproxy.cfg
    COUNT=$((COUNT + 1))
done

echo "=> Starting HAProxy"
exec "/docker-entrypoint.sh" "$@"