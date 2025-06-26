# NATS JetStream Cluster - Docker Compose Setup

🚀 完整的 NATS JetStream 集群配置，適用於微服務間消息傳遞

## 📋 項目概述

本項目提供了一個生產就緒的 NATS JetStream 3節點集群配置，包含：

- ✅ **3節點 NATS JetStream 集群**（每節點4GB存儲）
- ✅ **多租戶帳戶系統**（開發、生產、微服務隔離）
- ✅ **完整的訪問控制**（基於主題的細粒度權限）
- ✅ **HTTP 監控介面**（每節點獨立監控）
- ✅ **數據持久化**（自動volume掛載）
- ✅ **健康檢查**（自動故障檢測）
- ✅ **日誌記錄**（結構化日誌輸出）

## 🚀 快速開始

### 1. 啟動集群

```bash
# 啟動服務
docker compose up -d

# 檢查狀態  
docker compose ps
```

### 2. 驗證部署

```bash
# 運行測試腳本
./test-cluster.sh
```

### 3. 連接到集群

```bash
# 使用管理員帳戶連接（需要安裝 nats CLI）
nats --server="nats://admin:nats123@localhost:4222" server info

# 使用開發環境帳戶
nats --server="nats://dev-user:dev123@localhost:4222" server info
```

## 🔧 服務端點

### 客戶端連接
- **Node 1**: `nats://localhost:4222`
- **Node 2**: `nats://localhost:4223` 
- **Node 3**: `nats://localhost:4224`

### 監控介面
- **Node 1 監控**: http://localhost:8222
- **Node 2 監控**: http://localhost:8223
- **Node 3 監控**: http://localhost:8224

### 健康檢查端點
```bash
curl http://localhost:8222/healthz  # Node 1
curl http://localhost:8223/healthz  # Node 2  
curl http://localhost:8224/healthz  # Node 3
```

## 🔐 帳戶與權限

### 管理員帳戶 (ADMIN)
```
用戶: admin
密碼: nats123
權限: 完整存取權限 (所有主題)
```

### 開發環境帳戶 (DEV)
```
用戶: dev-user
密碼: dev123
權限: dev.*, logs.dev.*, metrics.dev.*
```

### 生產環境帳戶 (PROD)
```
用戶: prod-user
密碼: prod456
權限: prod.*, logs.prod.*, metrics.prod.*, alerts.*
```

### 微服務帳戶範例
```bash
# 用戶服務
用戶: user-service
密碼: user789

# 訂單服務  
用戶: order-service
密碼: order789

# 支付服務
用戶: payment-service
密碼: payment789

# 通知服務
用戶: notification-service
密碼: notify789
```

## 📊 JetStream 配置

每個節點配置：
- **記憶體存儲**: 1GB
- **檔案存儲**: 4GB  
- **集群域**: nats-cluster
- **複製因子**: 3 (高可用性)

## 🔧 常用命令

### 服務管理
```bash
# 啟動所有服務
docker compose up -d

# 停止所有服務
docker compose down

# 重啟特定服務
docker compose restart nats-node1

# 查看日誌
docker compose logs nats-node1 -f
```

### 集群監控
```bash
# 檢查集群狀態
curl -s http://localhost:8222/routez

# 檢查 JetStream 狀態  
curl -s http://localhost:8222/jsz

# 檢查帳戶資訊
curl -s http://localhost:8222/accountz
```

## 📈 監控與指標

### 內建監控端點
```bash
# 服務器資訊
curl http://localhost:8222/varz

# 連接資訊  
curl http://localhost:8222/connz

# JetStream 資訊
curl http://localhost:8222/jsz
```

### Prometheus 監控
本項目包含兩個 Prometheus Exporter：

**1. NATS Surveyor (端口 7777)**
```bash
# 查看可用指標
curl http://localhost:7777/metrics

# 指標涵蓋：帳戶統計、連接數、JetStream 資訊等
# 可用指標數量：約 45 個指標組
```

**2. NATS Prometheus Exporter (端口 7778)**  
```bash
# 查看額外指標
curl http://localhost:7778/metrics

# 指標涵蓋：連接詳情、路由資訊、訂閱統計等
```

**Prometheus 配置範例**
```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'nats-surveyor'
    static_configs:
      - targets: ['localhost:7777']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'nats-exporter'
    static_configs:
      - targets: ['localhost:7778']
    metrics_path: '/metrics'
    scrape_interval: 30s
```

## 🔧 管理工具

### NATS Box CLI 工具
本項目包含 NATS Box 容器，提供完整的 NATS 管理工具：

```bash
# 基本連接測試
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" pub test.hello "Hello NATS"

# 查看可用命令
docker compose exec nats-box nats --help

# 使用 NATS Top 監控
docker compose exec nats-box nats-top --server="nats://admin:nats123@nats-node1:4222"

# 效能測試
docker compose exec nats-box nats-bench --server="nats://admin:nats123@nats-node1:4222" test.bench
```

### JetStream 管理
```bash
# 創建 Stream
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" \
  stream create ORDERS --subjects "orders.*" --storage file --replicas 3

# 創建 Consumer  
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" \
  consumer create ORDERS ORDER_PROCESSOR --pull --deliver all

# 發布訊息到 Stream
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" \
  pub orders.created '{"order_id": "12345", "amount": 99.99}'
```

## 🛠️ 故障排除

### 常見問題

**1. JetStream 顯示 "等待 meta leader 選舉"**
- ✅ 正常現象，集群啟動需要選舉 leader
- ⏱️ 通常在 30-60 秒內完成

**2. 節點無法連接**
- 檢查端口是否被佔用: `netstat -tlnp | grep :4222`
- 檢查防火牆設置

**3. 權限被拒絕**
- 確認使用正確的帳戶/密碼
- 檢查主題權限配置

## 📂 項目結構

```
docker-nats-cluster/
├── docker-compose.yaml          # Docker Compose 配置
├── config/                      # NATS 配置文件
│   ├── accounts.conf           # 帳戶與權限配置  
│   ├── nats-node1.conf         # Node 1 配置
│   ├── nats-node2.conf         # Node 2 配置
│   └── nats-node3.conf         # Node 3 配置
├── data/                       # 數據持久化目錄
├── test-cluster.sh             # 集群測試腳本
└── README.md                   # 本文檔
```

## 🔗 相關資源

- **NATS 官方文檔**: https://docs.nats.io/
- **JetStream 指南**: https://docs.nats.io/nats-concepts/jetstream
- **NATS CLI 工具**: https://github.com/nats-io/natscli

## 📝 版本資訊

- **NATS Server**: 2.10.29-alpine
- **Docker Compose**: 3.8+
- **最後更新**: 2024年

## 📊 完整監控解決方案

本項目整合了企業級的 NATS JetStream 監控堆疊：

### 🎯 監控功能
- **指標監控**: 雙重 Prometheus Exporter 提供 45+ 指標
- **日誌聚合**: Loki + Promtail 自動收集分析日誌
- **視覺化**: Grafana 儀表板實時監控集群狀態
- **告警**: 可配置的告警規則和通知

### 🚀 快速存取
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100

### 📈 包含儀表板
1. **NATS JetStream 集群監控**: 核心指標和效能
2. **NATS 日誌分析**: 結構化日誌查詢和分析

### 📚 詳細說明
完整的監控設定和使用指南請參考 [MONITORING_GUIDE.md](./MONITORING_GUIDE.md)

---
