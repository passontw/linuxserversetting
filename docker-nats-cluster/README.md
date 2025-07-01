# NATS JetStream Cluster - Docker Compose Setup

🚀 完整的 NATS JetStream 集群配置，適用於微服務間消息傳遞

## 📋 項目概述

本項目提供了一個生產就緒的 NATS JetStream 3節點集群配置，包含：

- ✅ **3節點 NATS JetStream 集群**（每節點16GB存儲）
- ✅ **多租戶帳戶系統**（開發、生產、微服務隔離）
- ✅ **完整的訪問控制**（基於主題的細粒度權限）
- ✅ **HTTP 監控介面**（每節點獨立監控）
- ✅ **企業級監控堆疊**（Grafana + Prometheus + Loki）
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

# 或運行修復和測試腳本
./fix-and-test.sh
```

### 3. 連接到集群

```bash
# 使用管理員帳戶連接（需要安裝 nats CLI）
nats --server="nats://admin:nats123@localhost:4222" server info

# 使用開發環境帳戶
nats --server="nats://dev-user:dev123@localhost:4222" server info

# 使用 Docker 內建的 nats CLI
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" server info
```

## 🔧 服務端點

### 客戶端連接
- **Node 1**: `nats://localhost:4222`
- **Node 2**: `nats://localhost:4223` 
- **Node 3**: `nats://localhost:4224`

### NATS 監控介面
- **Node 1 監控**: http://localhost:8222
- **Node 2 監控**: http://localhost:8223
- **Node 3 監控**: http://localhost:8224

### 監控和管理服務
- **Grafana 儀表板**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Loki 日誌**: http://localhost:3100
- **NATS Surveyor**: http://localhost:7777
- **NATS Exporter**: http://localhost:7778

### 健康檢查端點
```bash
curl http://localhost:8222/varz   # Node 1 (正確端點)
curl http://localhost:8223/varz   # Node 2  
curl http://localhost:8224/varz   # Node 3
```

## 🔐 帳戶與權限

### 系統帳戶 (SYS) - 系統管理專用
```
用戶: sys-user
密碼: sys123
權限: 系統主題 ($SYS.>) 和請求回應 (_INBOX.>)
用途: 系統查詢和管理操作
```

### 管理員帳戶 (ADMIN)
```
用戶: admin
密碼: nats123
權限: 完整存取權限 (所有主題)
JetStream 配額: 4GB 記憶體, 16GB 檔案, 1000 流, 10000 消費者
```

### 開發環境帳戶 (DEV)
```
用戶: dev-user
密碼: dev123
權限: dev.*, logs.dev.*, metrics.dev.*
JetStream 配額: 4GB 記憶體, 16GB 檔案, 1000 流, 10000 消費者
```

### 生產環境帳戶 (PROD)
```
用戶: prod-user
密碼: prod456
權限: prod.*, logs.prod.*, metrics.prod.*, alerts.*
JetStream 配額: 4GB 記憶體, 16GB 檔案, 1000 流, 10000 消費者
```

### 監控帳戶 (MONITORING) - 監控系統專用
```
用戶: monitor-user
密碼: monitor123
權限: 所有主題 (>), 系統主題 ($SYS.>), 系統請求 ($SYS.REQ.>)
用途: Prometheus 監控、日誌收集、健康檢查
JetStream 配額: 4GB 記憶體, 16GB 檔案, 1000 流, 10000 消費者
```

### 微服務帳戶範例 (SERVICES)
```bash
# 用戶服務
用戶: user-service
密碼: user789
權限: services.user.>, events.user.>, notifications.user.>

# 訂單服務  
用戶: order-service
密碼: order789
權限: services.order.>, events.order.>, notifications.order.>

# 支付服務
用戶: payment-service
密碼: payment789
權限: services.payment.>, events.payment.>, notifications.payment.>

# 通知服務
用戶: notification-service
密碼: notify789
權限: notifications.send.>, events.notification.>
```

## 📊 JetStream 配置

每個節點配置：
- **記憶體存儲**: 4GB (已升級)
- **檔案存儲**: 16GB (已升級)  
- **集群域**: nats-cluster
- **複製因子**: 3 (高可用性)
- **最大流數**: 1000 (已升級)
- **最大消費者數**: 10000 (已升級)

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

# 查看所有服務狀態
docker compose ps
```

### 集群監控
```bash
# 檢查集群狀態
curl -s http://localhost:8222/routez

# 檢查 JetStream 狀態  
curl -s http://localhost:8222/jsz

# 檢查帳戶資訊
curl -s http://localhost:8222/accountz

# 檢查連接狀況
curl -s http://localhost:8222/connz
```

### 帳戶驗證
```bash
# 測試系統帳戶 (可查詢系統資訊)
docker compose exec nats-box nats --server="nats://sys-user:sys123@nats-node1:4222" server info

# 測試管理員帳戶
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" server info

# 測試監控帳戶
docker compose exec nats-box nats --server="nats://monitor-user:monitor123@nats-node1:4222" server info
```

## 📈 完整監控解決方案

本項目整合了企業級的 NATS JetStream 監控堆疊：

### 🎯 監控架構
- **指標收集**: NATS Surveyor (45+ 指標) + NATS Prometheus Exporter
- **指標存儲**: Prometheus (時序資料庫)
- **日誌聚合**: Loki + Promtail (自動收集 Docker 容器日誌)
- **視覺化**: Grafana 儀表板 (實時監控集群狀態)
- **告警**: 可配置的告警規則和通知

### 🚀 監控端點
```bash
# Prometheus 指標
curl http://localhost:7777/metrics  # NATS Surveyor (主要)
curl http://localhost:7778/metrics  # NATS Exporter (額外)

# 監控服務
curl http://localhost:9090/-/healthy    # Prometheus 健康檢查
curl http://localhost:3100/ready        # Loki 健康檢查
curl http://localhost:3000/api/health   # Grafana 健康檢查
```

### 📊 Grafana 儀表板
1. **NATS JetStream 集群監控**: 核心指標和效能分析
2. **NATS 日誌分析**: 結構化日誌查詢和分析

### 📚 監控指南
完整的監控設定和使用指南請參考 [MONITORING_GUIDE.md](./MONITORING_GUIDE.md)

## 📈 內建監控端點

### NATS 服務器端點
```bash
# 服務器資訊
curl http://localhost:8222/varz

# 連接資訊  
curl http://localhost:8222/connz

# JetStream 資訊
curl http://localhost:8222/jsz

# 集群路由資訊
curl http://localhost:8222/routez

# 帳戶資訊
curl http://localhost:8222/accountz
```

### Prometheus 監控配置
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

# 查看 Stream 列表
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" stream ls

# 查看 Consumer 資訊
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" consumer info ORDERS ORDER_PROCESSOR
```

## 🚨 重要修復記錄

本項目已解決以下關鍵問題，確保生產環境穩定性：

### ✅ 已修復的問題

#### 1. Loki 服務重啟問題
**問題**: `failed parsing config: line 58: field interface not found in type ring.LifecyclerConfig`
**解決**: 移除 `interface: eth0` 配置，簡化為單節點模式

#### 2. NATS 健康檢查失敗
**問題**: 健康檢查使用錯誤端點 `/healthz`
**解決**: 改用正確端點 `/varz`，調整檢查間隔和超時設定

#### 3. NATS Surveyor 重啟循環
**問題**: 啟動命令包含不支援的參數
**解決**: 移除不支援的 `--timeout`、`--poll-timeout`、`--no-color` 參數

#### 4. 權限配置問題
**問題**: 帳戶缺少 `_INBOX.*` 權限，無法執行請求-回應操作
**解決**: 為所有帳戶添加 `_INBOX.*` 權限，新增專用的系統帳戶

#### 5. JetStream 配額限制
**問題**: 原始配額過小，影響生產使用
**解決**: 升級所有帳戶配額至 4GB 記憶體、16GB 檔案存儲

### 🔧 配置改進

#### 系統帳戶分離
- 新增專用的 SYS 帳戶用於系統管理
- 分離監控帳戶，避免權限混亂
- 確保請求-回應模式正常工作

#### 監控架構完善
- 整合 Grafana + Prometheus + Loki 完整監控堆疊
- 自動日誌收集和分析
- 實時指標監控和告警

## 🛠️ 故障排除

### 常見問題診斷

#### 1. 服務無法啟動
```bash
# 檢查服務狀態
docker compose ps

# 查看服務日誌
docker compose logs [service-name] --tail=50

# 檢查端口佔用
netstat -tlnp | grep -E "4222|4223|4224|8222|8223|8224"
```

#### 2. NATS 節點連接問題
```bash
# 檢查節點健康狀態
curl http://localhost:8222/varz
curl http://localhost:8223/varz
curl http://localhost:8224/varz

# 檢查集群路由
curl http://localhost:8222/routez | jq '.routes | length'

# 測試帳戶連接
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" server info
```

#### 3. JetStream 問題
```bash
# 檢查 JetStream 狀態
curl http://localhost:8222/jsz

# 如果顯示 "等待 meta leader 選舉"
# ✅ 正常現象，集群啟動需要選舉 leader
# ⏱️ 通常在 30-60 秒內完成

# 檢查 JetStream 配置
docker compose exec nats-box nats --server="nats://admin:nats123@nats-node1:4222" server report jetstream
```

#### 4. 權限被拒絕
```bash
# 檢查帳戶權限
curl http://localhost:8222/accountz

# 確認使用正確的帳戶和密碼
# 檢查主題權限是否符合帳戶配置

# 系統級操作使用系統帳戶
docker compose exec nats-box nats --server="nats://sys-user:sys123@nats-node1:4222" server info
```

#### 5. 監控服務問題
```bash
# 檢查 Grafana
curl http://localhost:3000/api/health

# 檢查 Prometheus
curl http://localhost:9090/-/healthy

# 檢查 Loki
curl http://localhost:3100/ready

# 檢查 NATS Surveyor
curl http://localhost:7777/metrics | head -20
```

### 常見錯誤和解決方案

| 錯誤信息 | 可能原因 | 解決方案 |
|---------|---------|---------|
| `Permissions Violation for Publish` | 帳戶權限不足 | 檢查帳戶權限配置，使用有權限的帳戶 |
| `failed parsing config: field interface not found` | Loki 配置問題 | 檢查 loki-config.yml，移除不支援的字段 |
| `Connection refused` | 服務未啟動或端口問題 | 檢查服務狀態和端口佔用 |
| `waiting for meta leader` | JetStream 領導者選舉中 | 等待 30-60 秒，屬於正常啟動過程 |
| `command not found` | CLI 工具未安裝 | 使用 Docker 內建工具：`docker compose exec nats-box nats` |

### 重啟修復流程
```bash
# 完整重啟修復流程
./fix-and-test.sh

# 或手動執行
docker compose down
docker compose up -d
sleep 60
./test-cluster.sh
```

## 🎯 最佳實踐

### 生產環境建議

#### 1. 安全性
- **修改預設密碼**: 更改所有預設帳戶密碼
- **限制網路存取**: 使用防火牆限制 NATS 和監控端口存取
- **TLS 加密**: 啟用 TLS 加密客戶端連接
- **定期更新**: 保持 NATS 和監控組件最新版本

#### 2. 資源管理
- **記憶體監控**: 監控 JetStream 記憶體使用率，超過 80% 時擴容
- **存儲管理**: 定期清理舊的 Stream 和日誌檔案
- **連接限制**: 監控連接數，超過 1000 時考慮負載均衡
- **配額調整**: 根據實際使用情況調整 JetStream 配額

#### 3. 監控和告警
- **設定告警**: 配置 CPU、記憶體、存儲使用率告警
- **日誌監控**: 設定錯誤日誌告警規則
- **健康檢查**: 定期執行健康檢查腳本
- **備份策略**: 定期備份 JetStream 資料和配置

#### 4. 效能優化
- **連接池**: 客戶端使用連接池減少連接開銷
- **批次處理**: 使用批次發布提高吞吐量
- **適當複製**: 根據重要性選擇合適的複製因子
- **主題設計**: 合理設計主題結構避免權限複雜化

### 開發環境建議

#### 1. 帳戶分離
- **環境隔離**: 開發、測試、生產使用不同帳戶
- **權限最小化**: 只授予必要的主題權限
- **測試帳戶**: 使用專門的測試帳戶進行開發

#### 2. 除錯工具
- **使用 NATS Box**: 利用內建的 CLI 工具進行除錯
- **監控儀表板**: 使用 Grafana 儀表板監控開發過程
- **日誌查詢**: 使用 Loki 查詢和分析應用日誌

## 📂 項目結構

```
docker-nats-cluster/
├── docker-compose.yaml          # Docker Compose 配置
├── config/                      # NATS 配置文件
│   ├── accounts.conf           # 帳戶與權限配置 (已更新)
│   ├── nats-node1.conf         # Node 1 配置
│   ├── nats-node2.conf         # Node 2 配置
│   └── nats-node3.conf         # Node 3 配置
├── monitoring/                  # 監控配置文件
│   ├── grafana/                # Grafana 配置和儀表板
│   ├── prometheus/             # Prometheus 配置
│   ├── promtail/               # Promtail 日誌收集配置
│   └── loki/                   # Loki 日誌聚合配置
├── data/                       # 數據持久化目錄
├── test-cluster.sh             # 集群測試腳本
├── fix-and-test.sh             # 修復和測試腳本 (新增)
├── MONITORING_GUIDE.md         # 監控使用指南 (新增)
└── README.md                   # 本文檔 (已更新)
```

## 🔗 相關資源

### 官方文檔
- **NATS 官方文檔**: https://docs.nats.io/
- **JetStream 指南**: https://docs.nats.io/nats-concepts/jetstream
- **NATS CLI 工具**: https://github.com/nats-io/natscli
- **NATS 監控**: https://docs.nats.io/running-a-nats-service/nats_admin/monitoring

### 監控工具
- **Grafana 文檔**: https://grafana.com/docs/
- **Prometheus 文檔**: https://prometheus.io/docs/
- **Loki 文檔**: https://grafana.com/docs/loki/

### 相關工具
- **NATS Surveyor**: https://github.com/nats-io/nats-surveyor
- **NATS Prometheus Exporter**: https://github.com/nats-io/prometheus-nats-exporter
- **NATS Top**: https://github.com/nats-io/nats-top
- **NATS Bench**: https://github.com/nats-io/nats.go

## 📝 版本資訊與更新記錄

- **NATS Server**: 2.10-alpine
- **Docker Compose**: 3.8+
- **Grafana**: latest
- **Prometheus**: latest
- **Loki**: latest

### 🆕 最新更新 (2024年)
- ✅ 修復 Loki 配置兼容性問題
- ✅ 修復 NATS 健康檢查端點
- ✅ 修復 NATS Surveyor 啟動參數
- ✅ 完善帳戶權限配置，新增系統帳戶
- ✅ 升級 JetStream 配額限制
- ✅ 整合完整的企業級監控堆疊
- ✅ 新增故障排除和最佳實踐指南

---

**🎉 享受高效能的 NATS JetStream 消息傳遞體驗！**

如有問題，請查看故障排除章節或執行 `./fix-and-test.sh` 腳本進行診斷。
