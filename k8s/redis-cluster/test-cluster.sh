#!/bin/bash

# Redis Cluster 測試腳本

set -e

echo "=== Redis Cluster 測試 ==="

# 獲取密碼
REDIS_PASSWORD=$(kubectl get secret --namespace redis-cluster redis-cluster -o jsonpath="{.data.redis-password}" | base64 -d)

echo "1. 測試集群狀態..."
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD cluster info

echo
echo "2. 測試集群節點..."
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD cluster nodes

echo
echo "3. 測試基本數據操作..."
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c set test-key "Hello Redis Cluster"
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c get test-key

echo
echo "4. 測試分片功能..."
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c set '{user1}:name' 'Alice'
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c set '{user1}:age' '25'
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c mget '{user1}:name' '{user1}:age'

echo
echo "5. 測試多個鍵的分布..."
for i in {1..10}; do
    kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c set "key$i" "value$i" > /dev/null
done
echo "已設置 key1-key10"

echo
echo "6. 查看資源使用..."
kubectl top pods -n redis-cluster

echo
echo "Redis Cluster 測試完成！"