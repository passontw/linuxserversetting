# Kubernetes 集群部署記錄

本文檔記錄了 Kubernetes 集群中各服務的部署狀態和連接資訊。

## 已部署服務

### 1. PostgreSQL 數據庫

**部署狀態：** ✅ 已部署並運行  
**部署時間：** 2025-08-24  
**版本：** PostgreSQL 17.5  
**存儲：** Longhorn (8Gi)  

**連接資訊：**
```
# 內部連接 (集群內部)
主機: postgresql.postgresql.svc.cluster.local
端口: 5432
數據庫: postgres
用戶名: postgres
密碼: postgres123

# 外部連接 (NodePort)
主機: 172.237.27.51
端口: 30432
數據庫: postgres
用戶名: postgres
密碼: postgres123
```

**連接字符串：**
```bash
# 內部連接
postgresql://postgres:postgres123@postgresql.postgresql.svc.cluster.local:5432/postgres

# 外部連接
postgresql://postgres:postgres123@172.237.27.51:30432/postgres
```

**部署配置：**
- 命名空間: postgresql
- 存儲類: longhorn
- 服務類型: NodePort
- 資源配置: CPU 100m-500m, 記憶體 128Mi-1Gi

**管理腳本：**
```bash
# 測試連接
./k8s/postgresql/test-connection.sh

# 重新部署
./k8s/postgresql/deploy.sh

# 卸載
./k8s/postgresql/uninstall.sh
```

**常用操作：**
```bash
# 查看 Pod 狀態
kubectl get pods -n postgresql

# 查看服務狀態
kubectl get svc -n postgresql

# 查看 PVC 狀態
kubectl get pvc -n postgresql

# 查看日誌
kubectl logs -n postgresql postgresql-0

# 連接到數據庫
kubectl run postgresql-client --image postgres:15 --restart=Never --env="PGPASSWORD=postgres123" -- \
  psql -h postgresql.postgresql.svc.cluster.local -U postgres -d postgres
```

---

### 2. Redis Cluster 緩存

**部署狀態：** ✅ 已部署並運行  
**部署時間：** 2025-08-24 (檢查)  
**版本：** Redis 8.0.3  
**存儲：** Longhorn (2Gi × 3 節點)  

**集群配置：**
```
節點數: 3 主節點
副本數: 0 (最小化配置)
分片: 16384 個槽位
集群狀態: cluster_state:ok
```

**連接資訊：**
```
# 內部連接 (集群內部)
節點 1: redis-cluster-0.redis-cluster-headless.redis-cluster.svc.cluster.local:6379
節點 2: redis-cluster-1.redis-cluster-headless.redis-cluster.svc.cluster.local:6379
節點 3: redis-cluster-2.redis-cluster-headless.redis-cluster.svc.cluster.local:6379
密碼: 7vOXkhBGfT

# 外部連接 (NodePort)
主機: 172.237.27.51
端口: 30379 (所有節點共用)
密碼: 7vOXkhBGfT
```

**連接字符串：**
```bash
# 內部連接 (集群模式)
redis://redis-cluster.redis-cluster.svc.cluster.local:6379

# 外部連接
redis://172.237.27.51:30379
```

**部署配置：**
- 命名空間: redis-cluster
- 存儲類: longhorn
- 服務類型: NodePort (30379)
- 資源配置: CPU 50m-200m, 記憶體 64Mi-256Mi (每節點)

**管理腳本：**
```bash
# 測試集群
./k8s/redis-cluster/test-cluster.sh

# 簡單連接測試
./k8s/redis-cluster/simple-connection.sh

# 重新部署
./k8s/redis-cluster/deploy.sh

# 卸載
./k8s/redis-cluster/uninstall.sh
```

**常用操作：**
```bash
# 查看集群狀態
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a 7vOXkhBGfT cluster info

# 查看集群節點
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a 7vOXkhBGfT cluster nodes

# 測試數據操作
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a 7vOXkhBGfT -c set mykey "test"
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a 7vOXkhBGfT -c get mykey

# 查看 Pod 狀態
kubectl get pods -n redis-cluster

# 查看資源使用
kubectl top pods -n redis-cluster
```

### 3. Backend Service 後端服務

**部署狀態：** ✅ 已部署並運行  
**部署時間：** 2025-08-24  
**版本：** v1.0.0 (nginx placeholder)  
**副本數：** 2 個 Pod

**服務配置：**
```
鏡像: nginx:1.21-alpine (臨時佔位符)
副本數: 2
資源配置: CPU 100m-500m, 記憶體 128Mi-512Mi
重啟策略: Always
```

**連接資訊：**
```
# 內部連接 (集群內部)
服務名稱: backend-service.backend-service.svc.cluster.local
端口: 8080
健康檢查: http://backend-service.backend-service.svc.cluster.local:8080/health

# 外部連接 (NodePort)
主機: 172.237.27.51
端口: 30080
健康檢查: http://172.237.27.51:30080/health
```

**環境變數配置：**
```bash
# PostgreSQL 連接
POSTGRES_HOST=postgresql.postgresql.svc.cluster.local
POSTGRES_PORT=5432
POSTGRES_DATABASE=postgres
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=postgres123

# Redis Cluster 連接
REDIS_CLUSTER_HOSTS=redis-cluster.redis-cluster.svc.cluster.local:6379
REDIS_CLUSTER_MODE=cluster
REDIS_PASSWORD=7vOXkhBGfT

# 應用配置
APP_ENV=development
APP_PORT=8080
LOG_LEVEL=info
```

**部署配置：**
- 命名空間: backend-service
- 服務類型: NodePort (30080)
- ConfigMap: backend-service-config
- Secret: backend-service-secret

**管理腳本：**
```bash
# 測試服務
./k8s/backend-service/test-service.sh

# 重新部署
./k8s/backend-service/deploy.sh

# 卸載
./k8s/backend-service/uninstall.sh
```

**常用操作：**
```bash
# 查看 Pod 狀態
kubectl get pods -n backend-service

# 查看服務狀態
kubectl get svc -n backend-service

# 查看環境變數
kubectl exec -n backend-service deployment/backend-service -- env | grep -E '(POSTGRES|REDIS|APP)'

# 查看日誌
kubectl logs -n backend-service deployment/backend-service

# 測試外部訪問
curl http://172.237.27.51:30080/

# 進入容器
kubectl exec -n backend-service -it deployment/backend-service -- /bin/sh
```

---

## 部署歷史

| 服務 | 版本 | 部署日期 | 狀態 | 備註 |
|------|------|----------|------|------|
| PostgreSQL | 17.5 | 2025-08-24 | ✅ 運行中 | 使用 Longhorn 存儲 |
| Redis Cluster | 8.0.3 | 2025-08-24 | ✅ 運行中 | 3 主節點，Longhorn 存儲 |
| Backend Service | v1.0.0 | 2025-08-24 | ✅ 運行中 | nginx 佔位符，2 副本 |
| NATS Cluster | - | 之前 | ✅ 運行中 | 消息中間件 |

## 註意事項

1. **存儲依賴：** PostgreSQL 和 Redis Cluster 都使用 Longhorn 作為存儲後端，確保 Longhorn 正常運行
2. **網路訪問：** 
   - PostgreSQL NodePort: 30432
   - Redis Cluster NodePort: 30379
   - Backend Service NodePort: 30080
   - 確保防火牆允許這些端口
3. **備份策略：** 
   - PostgreSQL：建議定期備份數據庫
   - Redis Cluster：考慮使用 AOF/RDB 持久化配置
4. **監控：** 定期檢查資源使用情況和日誌
5. **Redis Cluster 集群模式：** 應用程式需要使用支持集群模式的 Redis 客戶端
6. **密碼管理：** Redis 和 PostgreSQL 密碼存儲在 Kubernetes Secret 中，定期輪換密碼
7. **Backend Service：** 
   - 目前使用 nginx 作為佔位符鏡像
   - 環境變數已預配置好 PostgreSQL 和 Redis 連接
   - 需要替換為實際的應用程式鏡像
8. **服務依賴：** Backend Service 依賴 PostgreSQL 和 Redis Cluster，確保這些服務先啟動

## 故障排除

**PostgreSQL 常見問題：**

1. **Pod 無法啟動**
   ```bash
   kubectl describe pod -n postgresql postgresql-0
   kubectl logs -n postgresql postgresql-0
   ```

2. **存儲問題**
   ```bash
   kubectl get pvc -n postgresql
   kubectl describe pvc -n postgresql data-postgresql-0
   ```

3. **網路連接問題**
   ```bash
   kubectl get svc -n postgresql
   kubectl describe svc -n postgresql postgresql
   ```

**Redis Cluster 常見問題：**

1. **集群狀態異常**
   ```bash
   kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a 7vOXkhBGfT cluster info
   kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a 7vOXkhBGfT cluster nodes
   ```

2. **認證失敗**
   ```bash
   # 獲取正確密碼
   kubectl get secret --namespace redis-cluster redis-cluster -o jsonpath='{.data.redis-password}' | base64 -d
   ```

3. **數據分片問題**
   ```bash
   # 檢查槽位分配
   kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a 7vOXkhBGfT cluster slots
   ```

4. **連接超時**
   ```bash
   # 檢查 Pod 和服務狀態
   kubectl get pods -n redis-cluster
   kubectl get svc -n redis-cluster
   kubectl describe svc -n redis-cluster redis-cluster
   ```

**Backend Service 常見問題：**

1. **服務無法啟動**
   ```bash
   kubectl describe pod -n backend-service
   kubectl logs -n backend-service deployment/backend-service
   ```

2. **環境變數配置問題**
   ```bash
   # 檢查 ConfigMap 和 Secret
   kubectl get configmap -n backend-service backend-service-config -o yaml
   kubectl get secret -n backend-service backend-service-secret -o yaml
   
   # 檢查容器內環境變數
   kubectl exec -n backend-service deployment/backend-service -- env | grep -E '(POSTGRES|REDIS|APP)'
   ```

3. **服務連接問題**
   ```bash
   # 測試外部連接
   curl -v http://172.237.27.51:30080/
   
   # 檢查服務端點
   kubectl get endpoints -n backend-service
   kubectl describe svc -n backend-service backend-service
   ```

4. **依賴服務連接問題**
   ```bash
   # 從容器內測試 PostgreSQL 連接
   kubectl exec -n backend-service deployment/backend-service -- nslookup postgresql.postgresql.svc.cluster.local
   
   # 從容器內測試 Redis Cluster 連接
   kubectl exec -n backend-service deployment/backend-service -- nslookup redis-cluster.redis-cluster.svc.cluster.local
   ```

---

*最後更新：2025-08-24*