#!/bin/bash

# 初始化变量
SERVER=""
PORT="6379"
SENTINEL_PORT="26379"
PASSWORD="123456"
ROLE=""
IMAGE="harbor.tsingj.local/re_release/redis:7.2.3"

# 解析传入的参数
for i in "$@"
do
case $i in
    --server=*)
    SERVER="${i#*=}"
    shift
    ;;
    --port=*)
    PORT="${i#*=}"
    shift
    ;;
    --sentinel-port=*)
    SENTINEL_PORT="${i#*=}"
    shift
    ;;
    --password=*)
    PASSWORD="${i#*=}"
    shift
    ;;
    --role=*)
    ROLE="${i#*=}"
    shift
    ;;
    *)
    echo "Unknown option: $i"
    exit 1
    ;;
esac
done

# 检查必填参数
if [ -z "$SERVER" ]; then
    echo "--server is required."
    exit 1
fi

if [ -z "$ROLE" ]; then
    echo "--role is required (master or replica)."
    exit 1
fi

# 创建 Sentinel 配置文件
SENTINEL_CONFIG="$HOME/sentinel.conf"
cat <<EOL > $SENTINEL_CONFIG
sentinel monitor mymaster $SERVER $PORT 2
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
sentinel auth-pass mymaster $PASSWORD
requirepass $PASSWORD
EOL

# 判断部署主节点还是副本节点
if [ "$ROLE" == "master" ]; then
    echo "Installing Redis as master node with password $PASSWORD..."
    # 运行 Redis，配置为主节点
    docker run -d --name redis -p $PORT:$PORT $IMAGE \
        redis-server --port $PORT --requirepass $PASSWORD
elif [ "$ROLE" == "replica" ]; then
    echo "Installing Redis as a replica of $SERVER with password $PASSWORD..."
    # 运行 Redis，配置为副本节点
    docker run -d --name redis -p $PORT:$PORT $IMAGE \
        redis-server --port $PORT --replicaof $SERVER $PORT --requirepass $PASSWORD --masterauth $PASSWORD
else
    echo "Unknown role: $ROLE. Please specify 'master' or 'replica'."
    exit 1
fi

# 部署 Sentinel 副本节点
echo "Installing Redis Sentinel for replica..."
docker run -d --name redis_sentinel -p $SENTINEL_PORT:$SENTINEL_PORT \
    -v $SENTINEL_CONFIG:/etc/redis/sentinel.conf $IMAGE \
     redis-sentinel /etc/redis/sentinel.conf
