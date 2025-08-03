# NATS 集群部署指南

## 概述

本專案提供了一個完整的 NATS 集群部署解決方案，適用於 Kubernetes 測試環境。使用 Helm Chart 進行部署，支援 JetStream、用戶認證、持久化存儲等功能。

## 功能特性

- ✅ **3 節點集群**：高可用性配置
- ✅ **JetStream 支援**：持久化消息存儲
- ✅ **用戶認證**：多層級權限管理
- ✅ **持久化存儲**：使用 Longhorn Storage Class
- ✅ **動態資源配置**：最小配置，支援自動擴展
- ✅ **內外部連接**：NodePort 服務暴露
- ✅ **監控端口**：HTTP 監控介面

## 系統需求

### 必要條件

- Kubernetes 集群 (v1.19+)
- Helm 3.x
- Longhorn Storage Class
- kubectl 配置正確

### 推薦配置

- **CPU**: 每個節點至少 1 核心
- **記憶體**: 每個節點至少 2GB
- **存儲**: 每個節點至少 10GB 可用空間

## 快速開始

### 1. 克隆專案

```bash
git clone <repository-url>
cd k8s/nats-cluster
```

### 2. 檢查環境

```bash
# 檢查 kubectl 連接
kubectl cluster-info

# 檢查 Helm
helm version

# 檢查 Longhorn Storage Class
kubectl get storageclass longhorn
```

### 3. 部署 NATS 集群

```bash
# 給予執行權限
chmod +x deploy.sh

# 執行部署
./deploy.sh
```

### 4. 驗證部署

```bash
# 檢查 Pod 狀態
kubectl get pods -n nats

# 檢查服務狀態
kubectl get svc -n nats

# 檢查 PVC 狀態
kubectl get pvc -n nats
```

## 配置說明

### 集群配置

- **節點數量**: 3 個
- **集群名稱**: nats-cluster
- **命名空間**: nats

### 認證配置

| 用戶名 | 密碼 | 權限 | 說明 |
|--------|------|------|------|
| admin | admin123 | 全部權限 | 管理員用戶 |
| user1 | user123 | app.*, service.* | 一般用戶 |
| readonly | read123 | 只能訂閱 | 唯讀用戶 |

### 服務配置

#### 內部連接
- **NATS 服務**: `nats.nats.svc.cluster.local:4222`
- **監控服務**: `nats.nats.svc.cluster.local:8222`

#### 外部連接 (NodePort)
- **NATS 服務**: `<NODE_IP>:30222`
- **監控服務**: `<NODE_IP>:30822`

### 存儲配置

- **Storage Class**: longhorn
- **NATS 存儲**: 5Gi
- **JetStream 記憶體**: 1Gi (可動態擴展)
- **JetStream 檔案**: 10Gi

### 資源配置

```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 2Gi
```

## 使用指南

### 連接測試

#### 1. 內部連接測試

```bash
# 使用 kubectl 測試
kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- \
  nats-sub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 'test.>'
```

#### 2. 外部連接測試

```bash
# 獲取節點 IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')

# 測試連接
nats-sub -s nats://admin:admin123@${NODE_IP}:30222 'test.>'
```

### JetStream 使用

#### 1. 創建 Stream

```bash
kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- \
  nats stream add test-stream --subjects 'test.*' --storage file --replicas 3
```

#### 2. 發布消息

```bash
kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- \
  nats pub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 test.hello "Hello World"
```

#### 3. 訂閱消息

```bash
kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- \
  nats sub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 test.hello
```

### 監控和日誌

#### 1. 查看集群狀態

```bash
# 查看 Pod 日誌
kubectl logs -n nats deployment/nats

# 查看特定 Pod 日誌
kubectl logs -n nats nats-0
```

#### 2. 監控介面

訪問 `http://<NODE_IP>:30822` 查看 NATS 監控介面。

#### 3. 集群資訊

```bash
# 查看 Stream 列表
kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- \
  nats stream list

# 查看 Consumer 列表
kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- \
  nats consumer list
```

## 管理操作

### 擴展集群

```bash
# 擴展到 5 個節點
helm upgrade nats nats/nats -n nats --set nats.cluster.replicas=5
```

### 更新配置

```bash
# 更新 values.yaml 後重新部署
helm upgrade nats nats/nats -n nats -f values.yaml
```

### 備份和恢復

#### 備份 JetStream 數據

```bash
# 備份 PVC 數據
kubectl cp nats/nats-0:/data/jetstream ./backup/
```

#### 恢復數據

```bash
# 恢復數據到 PVC
kubectl cp ./backup/ nats/nats-0:/data/jetstream
```

### 卸載集群

```bash
# 給予執行權限
chmod +x uninstall.sh

# 執行卸載
./uninstall.sh
```

## 故障排除

### 常見問題

#### 1. Pod 無法啟動

```bash
# 檢查 Pod 狀態
kubectl describe pod -n nats nats-0

# 檢查事件
kubectl get events -n nats --sort-by='.lastTimestamp'
```

#### 2. PVC 綁定失敗

```bash
# 檢查 Storage Class
kubectl get storageclass

# 檢查 PVC 狀態
kubectl describe pvc -n nats
```

#### 3. 連接失敗

```bash
# 檢查服務狀態
kubectl get svc -n nats

# 檢查端口
kubectl get endpoints -n nats
```

#### 4. JetStream 錯誤

```bash
# 檢查 JetStream 狀態
kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- \
  nats server report

# 檢查存儲空間
kubectl exec -n nats nats-0 -- df -h
```

### 日誌分析

#### 1. 查看詳細日誌

```bash
# 啟用調試日誌
kubectl patch deployment nats -n nats --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args/0", "value": "--debug"}]'
```

#### 2. 查看錯誤日誌

```bash
# 查看錯誤日誌
kubectl logs -n nats deployment/nats --tail=100 | grep ERROR
```

## 性能調優

### 資源優化

#### 1. 記憶體配置

```yaml
# 根據使用量調整記憶體
resources:
  requests:
    memory: 512Mi
  limits:
    memory: 4Gi
```

#### 2. JetStream 配置

```yaml
# 調整 JetStream 存儲
jetstream:
  memStorage:
    size: 2Gi
  fileStorage:
    size: 20Gi
```

### 網路優化

#### 1. 服務配置

```yaml
# 使用 LoadBalancer 替代 NodePort
service:
  loadBalancer:
    enabled: true
    port: 4222
```

#### 2. 網路策略

```yaml
# 啟用網路策略
networkPolicy:
  enabled: true
```

## 安全配置

### TLS 加密

```yaml
# 啟用 TLS
tls:
  enabled: true
  secretName: nats-tls
```

### 用戶管理

```yaml
# 添加新用戶
auth:
  basic:
    users:
      - user: newuser
        password: "newpass123"
        permissions:
          publish:
            allow: ["app.>"]
          subscribe:
            allow: ["app.>"]
```

## 監控和告警

### Prometheus 監控

```yaml
# 啟用 Prometheus 監控
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

### Grafana 儀表板

使用 NATS 官方 Grafana 儀表板進行監控。

## 版本資訊

- **NATS 版本**: 最新穩定版
- **Helm Chart 版本**: 最新版本
- **Kubernetes 版本**: 1.19+
- **Longhorn 版本**: 最新版本

## 支援

如有問題，請檢查：

1. Kubernetes 集群狀態
2. Longhorn Storage Class 配置
3. 網路連接和防火牆設置
4. 資源使用情況

## 更新日誌

- **v1.0.0**: 初始版本，支援基本 NATS 集群部署
- 支援 JetStream、用戶認證、持久化存儲
- 提供完整的部署和卸載腳本 