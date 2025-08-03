# Redis Cluster 部署指南

## 概述

本專案提供了一個完整的 Redis Cluster 部署解決方案，適用於 Kubernetes 測試環境。使用 Helm Chart 進行部署，配置 3 主節點無副本的最小化集群架構。

## 功能特性

- ✅ **3 主節點集群**：無副本配置，最小化資源使用
- ✅ **持久化存儲**：使用 Longhorn Storage Class (2Gi 每節點)
- ✅ **外部訪問**：NodePort 服務暴露 (30379)
- ✅ **認證保護**：密碼認證
- ✅ **資源優化**：極小化配置，適合測試環境
- ✅ **數據持久化**：Redis 自動持久化

## 系統需求

- Kubernetes 集群 (v1.19+)
- Helm 3.x
- Longhorn Storage Class
- kubectl 配置正確

## 快速開始

### 1. 部署 Redis Cluster

```bash
# 創建命名空間
kubectl apply -f namespace.yaml

# 部署集群
helm install redis-cluster bitnami/redis-cluster \
  --namespace redis-cluster \
  --values values.yaml \
  --wait --timeout 15m
```

### 2. 測試集群

```bash
chmod +x test-cluster.sh
./test-cluster.sh
```

### 3. 卸載

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## 連接資訊

### 獲取密碼
```bash
export REDIS_PASSWORD=$(kubectl get secret --namespace redis-cluster redis-cluster -o jsonpath="{.data.redis-password}" | base64 -d)
echo $REDIS_PASSWORD
```

### 內部連接
- **服務**: redis-cluster.redis-cluster.svc.cluster.local:6379
- **節點 1**: redis-cluster-0.redis-cluster-headless.redis-cluster.svc.cluster.local:6379
- **節點 2**: redis-cluster-1.redis-cluster-headless.redis-cluster.svc.cluster.local:6379
- **節點 3**: redis-cluster-2.redis-cluster-headless.redis-cluster.svc.cluster.local:6379

### 外部連接 (NodePort) - 簡化版
- **🚀 主服務**: <NODE_IP>:30379 (負載均衡到所有節點)
- **🔐 密碼**: 使用上述命令獲取

**🎯 設計理念**: 開發者只需要記住一個連接點，Kubernetes 會自動負載均衡到集群的不同節點。適合大多數應用場景的簡化連接方式。

## 實際配置 (部署後)

### 集群狀態
```bash
# 檢查集群狀態
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD cluster info

# 檢查節點分布
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD cluster nodes
```

### 資源使用
- **CPU**: 實際使用 ~15m (每節點)
- **記憶體**: 實際使用 ~5Mi (每節點)
- **存儲**: 2Gi (每節點, Longhorn)
- **總資源**: 非常低的資源消耗

## 使用範例

### 基本操作
```bash
# 連接到集群
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c

# 設置數據
redis-cli> set mykey "Hello Redis Cluster"

# 獲取數據
redis-cli> get mykey
```

### 集群操作
```bash
# 測試分片
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c set test-key "Hello World"
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c get test-key

# 測試 Hash Tag (確保相關鍵在同一分片)
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c set '{user1}:name' 'Alice'
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c set '{user1}:age' '25'
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD -c mget '{user1}:name' '{user1}:age'
```

### 🚀 簡化外網連接 (推薦)

#### 快速開始
```bash
# 獲取連接資訊
./simple-connection.sh
```

#### 🔧 使用 redis-cli 連接
```bash
# 獲取節點 IP 和密碼
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' | cut -d' ' -f1)
REDIS_PASSWORD=$(kubectl get secret --namespace redis-cluster redis-cluster -o jsonpath="{.data.redis-password}" | base64 -d)

# 🎯 只需要一個連接點！
redis-cli -c -h $NODE_IP -p 30379 -a $REDIS_PASSWORD
```

#### 🐍 Python 客戶端範例
```python
import redis
from rediscluster import RedisCluster

# 🎯 方式 1: 單一節點集群連接 (推薦 - 最簡單)
startup_nodes = [{'host': '172.237.27.51', 'port': 30379}]
rc = RedisCluster(startup_nodes=startup_nodes, password='your_password', decode_responses=True)

# 🎯 方式 2: 標準 Redis 客戶端 (適用於簡單操作)
r = redis.Redis(host='172.237.27.51', port=30379, password='your_password', decode_responses=True)

# 測試操作
rc.set('test', 'Hello World')
print(rc.get('test'))
```

#### 🟢 Node.js 客戶端範例
```javascript
const Redis = require('ioredis');

// 🎯 方式 1: 單一節點集群連接 (推薦)
const cluster = new Redis.Cluster([{ host: '172.237.27.51', port: 30379 }], {
    redisOptions: { password: 'your_password' }
});

// 🎯 方式 2: 標準模式 (適用於簡單操作)
const redis = new Redis('172.237.27.51', 30379, { password: 'your_password' });

// 測試操作
cluster.set('test', 'Hello from Node.js')
    .then(() => cluster.get('test'))
    .then((result) => console.log(result));
```

#### ✅ 適用場景與限制
- **✅ 適用**: 快取、會話存儲、簡單鍵值操作
- **✅ 優點**: 連接簡單、自動負載均衡、故障轉移
- **⚠️ 限制**: 某些高級集群功能可能需要完整節點列表
- **🔄 負載均衡**: Kubernetes 自動分發到不同 Redis 節點

## 監控和維護

### 檢查狀態
```bash
# 查看 Pod 狀態
kubectl get pods -n redis-cluster

# 查看資源使用
kubectl top pods -n redis-cluster

# 查看存儲使用
kubectl get pvc -n redis-cluster

# 查看服務
kubectl get svc -n redis-cluster
```

### 查看日誌
```bash
# 查看特定節點日誌
kubectl logs -n redis-cluster redis-cluster-0
kubectl logs -n redis-cluster redis-cluster-1
kubectl logs -n redis-cluster redis-cluster-2
```

## 故障排除

### 常見問題

1. **認證失敗**
   ```bash
   # 獲取正確密碼
   kubectl get secret --namespace redis-cluster redis-cluster -o jsonpath="{.data.redis-password}" | base64 -d
   ```

2. **連接超時**
   - 檢查服務和端點配置
   - 確認防火牆設置

3. **數據分布不均**
   - 檢查集群節點狀態
   - 確認 slot 分配正常

### 集群重新平衡
```bash
# 查看 slot 分布
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a $REDIS_PASSWORD cluster slots
```

## 性能測試

### 基準測試
```bash
# 使用 redis-benchmark 測試性能
kubectl run redis-benchmark --rm -it --image redis:7 --restart=Never -- \
  redis-benchmark -h redis-cluster.redis-cluster.svc.cluster.local -p 6379 -a $REDIS_PASSWORD -c 50 -n 10000
```

## 升級和擴展

### 擴展集群 (注意：需要重新分配 slots)
```bash
# 升級為更多節點需要謹慎操作
helm upgrade redis-cluster bitnami/redis-cluster \
  --namespace redis-cluster \
  --set cluster.nodes=6 \
  --values values.yaml
```

## 版本資訊

- **Redis 版本**: 8.0.3
- **Helm Chart**: Bitnami Redis Cluster 12.0.13
- **架構**: 3 主節點，0 副本
- **存儲**: Longhorn 2Gi 每節點
- **資源使用**: 極低 (~15m CPU, ~5Mi Memory 每節點)

## 文件結構

```
k8s/redis-cluster/
├── namespace.yaml      # 命名空間定義
├── values.yaml         # Helm 配置值
├── deploy.sh          # 部署腳本
├── test-cluster.sh    # 測試腳本
├── uninstall.sh       # 卸載腳本
└── README.md          # 本文檔
```

## 安全考量

- 使用密碼認證
- 運行在非 root 用戶下
- 網路隔離在 Kubernetes namespace 中
- 持久化數據加密 (Longhorn 層級)

這個 Redis Cluster 配置適合測試環境，具有最小的資源佔用和良好的功能完整性。