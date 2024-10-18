# docker部署redis哨兵

## 部署说明

* redis哨兵必须是三个节点，且必须部署在三个不同的机器上
* redis主节点和从节点均使用docker部署

```bash
# redis.sh脚本可配置参数如下：
# --server: redis主节点ip（必填）
# --role: redis节点角色，master或replica（必填）
# --port: redis节点端口，默认6379（可选）
# --sentinel-port: redis哨兵端口，默认26379（可选）
# --password: redis节点密码，默认123456（可选）
```

## 部署步骤

### 默认安装

```shell
# 主节点安装
bash redis.sh --server=10.90.3.187 --role=master

# 从节点安装
bash redis.sh --server=10.90.3.187 --role=replica
```

### 指定端口安装

```shell
# 主节点安装
bash redis.sh --server=10.90.3.187 --role=master --port=6380 --sentinel-port=26380

# 从节点安装
bash redis.sh --server=10.90.3.187 --role=replica --port=6381 --sentinel-port=26381
```

### 指定密码安装

```shell
# 主节点安装
bash redis.sh --server=10.90.3.187 --role=master --password=123456

# 从节点安装
bash redis.sh --server=10.90.3.187 --role=replica --password=123456
```

## 验证

### 验证redis

```shell
# 查看redis节点信息（密码和端口根据实际情况填写）
docker exec -it redis redis-cli -a 123456 -p 6379 info replication
```

### 验证sentinel

```shell
# 查看哨兵信息（密码和端口根据实际情况填写）
docker exec -it redis_sentinel redis-cli -a 123456 -p 26379 sentinel get-master-addr-by-name mymaster

docker exec -it redis_sentinel redis-cli -a 123456 -p 26379 info sentinel
```

## 卸载步骤

```shell
# 停止并删除redis和redis_sentinel容器
docker rm -f redis redis_sentinel
```