#!/bin/bash

# Redis Cluster 簡化外網連接測試腳本
# 開發者只需要這一個連接點

set -e

# 獲取節點 IP (只取第一個 IP)
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' | cut -d' ' -f1)
echo "節點 IP: $NODE_IP"

# 獲取 Redis 密碼
REDIS_PASSWORD=$(kubectl get secret --namespace redis-cluster redis-cluster -o jsonpath="{.data.redis-password}" | base64 -d)
echo "Redis 密碼: $REDIS_PASSWORD"

echo
echo "=== Redis Cluster 簡化連接資訊 ==="
echo "🚀 只需要這一個連接點: $NODE_IP:30379"
echo "🔐 密碼: $REDIS_PASSWORD"
echo

echo "=== 測試連接 ==="
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -h $NODE_IP -p 30379 ping

echo
echo "=== 測試集群操作 ==="
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -h $NODE_IP -p 30379 -c set simple-test "Hello Simple Connection"
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -h $NODE_IP -p 30379 -c get simple-test

echo
echo "=== 開發者連接範例 ==="
echo
echo "🔧 使用 redis-cli:"
echo "redis-cli -c -h $NODE_IP -p 30379 -a $REDIS_PASSWORD"
echo
echo "🐍 Python 範例:"
echo "import redis"
echo "from rediscluster import RedisCluster"
echo ""
echo "# 方式 1: 使用單一節點 (最簡單)"
echo "startup_nodes = [{'host': '$NODE_IP', 'port': 30379}]"
echo "rc = RedisCluster(startup_nodes=startup_nodes, password='$REDIS_PASSWORD', decode_responses=True)"
echo ""
echo "# 方式 2: 使用標準 Redis 客戶端 (如果不需要完整集群功能)"
echo "r = redis.Redis(host='$NODE_IP', port=30379, password='$REDIS_PASSWORD', decode_responses=True)"
echo ""
echo "# 測試操作"
echo "rc.set('test', 'Hello World')"
echo "print(rc.get('test'))"
echo
echo "🟢 Node.js 範例:"
echo "const Redis = require('ioredis');"
echo ""
echo "// 方式 1: 集群模式"
echo "const cluster = new Redis.Cluster([{ host: '$NODE_IP', port: 30379 }], {"
echo "    redisOptions: { password: '$REDIS_PASSWORD' }"
echo "});"
echo ""
echo "// 方式 2: 單機模式 (簡單操作)"
echo "const redis = new Redis($NODE_IP, 30379, { password: '$REDIS_PASSWORD' });"
echo

echo "=== 注意事項 ==="
echo "✅ 適用場景: 簡單的鍵值操作、快取使用"
echo "⚠️  限制: 某些集群特定功能可能需要完整的節點列表"
echo "🔄 負載均衡: Kubernetes 會自動分發連接到不同的 Redis 節點"
echo

echo "=== 簡化連接配置完成 ==="