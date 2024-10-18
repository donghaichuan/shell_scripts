# k8s部署redis哨兵

## 安装redis哨兵模式

```bash
$ helm install redis-release ./ -n redis --create-namespace --wait
```

## 查看redis和redis-sentinel的pod

```bash
$ kubectl get pods -n redis
NAME                       READY   STATUS    RESTARTS   AGE
redis-0                    1/1     Running   0          2m
redis-1                    1/1     Running   0          2m
redis-2                    1/1     Running   0          2m
sentinel-0                 1/1     Running   0          2m
sentinel-1                 1/1     Running   0          2m
sentinel-2                 1/1     Running   0          2m
```

## 查看redis和redis-sentinel的service

```bash
$ kubectl get svc -n redis
NAME↑               TYPE      CLUSTER-IP  EXTERNAL-IP   PORTS                 AGE               
redis               ClusterIP                           redis:6379►0          2m              
sentinel            ClusterIP                           sentinel:26379►0      2m               
sentinel-service    NodePort              10.43.206.112 sentinel:26379►26379  2m
```

## 外部访问方式

```bash
# 通过k8s/k3s集群的IP和哨兵的nodePort连接redis-sentinel
$ redis-cli -h 10.90.x.x -p 26379
10.90.3.191:26379> auth 123456 # 连接redis-sentinel需要密码
10.90.3.191:26379> info sentinel # 查看哨兵信息
# Sentinel
sentinel_masters:1
sentinel_tilt:0
sentinel_tilt_since_seconds:-1
sentinel_running_scripts:0
sentinel_scripts_queue_length:0
sentinel_simulate_failure_flags:0
master0:name=mymaster,status=ok,address=redis-0.redis.redis.svc.cluster.local:6379,slaves=2,sentinels=3
```

## 自定义修改密码和端口

```bash
# 修改values.yaml文件
# 修改密码
password: 123456
# 修改redis-sentinel的nodePort
expose:
  type: nodePort
  nodePort:
    sentinel: 26379
```

## 卸载redis哨兵模式

```bash
$ helm uninstall redis-release -n redis
```
