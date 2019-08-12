#!/bin/bash

set -e

TAG=${1:-"latest"}

echo "Building haproxy"
docker build -t haproxy-redis:$TAG haproxy 
docker image tag haproxy-redis:$TAG haproxy-redis:latest

echo "Building redis-zero"
docker build -t redis-zero:$TAG redis-master
docker image tag redis-zero:$TAG redis-zero:latest

echo "Building redis-look"
docker build -t redis-look:$TAG redis-look 
docker image tag redis-look:$TAG redis-look:latest

echo "Building redis-sentinel"
docker build -t redis-sentinel:$TAG redis-sentinel 
docker image tag redis-sentinel:$TAG redis-sentinel:latest

echo "Building redis-utils"
docker build -t redis-utils:$TAG redis-utils 
docker image tag redis-utils:$TAG redis-utils:latest
