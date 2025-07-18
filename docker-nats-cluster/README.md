# NATS JetStream Cluster - Docker Compose Setup

🚀 完整的 NATS JetStream 集群配置，適用於微服務間消息傳遞

## 📋 項目概述

本項目提供了一個生產就緒的 NATS JetStream 3節點集群配置，包含：

- ✅ **3節點 NATS JetStream 集群**（每節點4GB存儲）
- ✅ **多租戶帳戶系統**（開發、生產、微服務隔離）
- ✅ **完整的訪問控制**（基於主題的細粒度權限）
- ✅ **HTTP 監控介面**（每節點獨立監控）
- ✅ **企業級監控堆疊**（Grafana + Prometheus）
- ✅ **數據持久化**（自動volume掛載）
- ✅ **健康檢查**（自動故障檢測）
- ✅ **日誌記錄**（結構化日誌輸出）

## 🚀 快速開始

### 1. 初始化數據目錄

```bash
# 創建必要的數據目錄結構
./init-data-dirs.sh
```

### 2. 啟動集群

```bash
# 啟動服務
docker compose up -d

# 檢查狀態  
docker compose ps
```

### 3. 驗證部署

```bash
# 運行測試腳本
./test-cluster.sh

# 或運行修復和測試腳本
./fix-and-test.sh
```

### 4. 連接到集群

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
JetStream 配額: 1GB 記憶體, 4GB 檔案, 1000 流, 10000 消費者
```

### 開發環境帳戶 (DEV)
```
用戶: dev-user
密碼: dev123
權限: dev.*, logs.dev.*, metrics.dev.*
JetStream 配額: 1GB 記憶體, 4GB 檔案, 1000 流, 10000 消費者
```

### 生產環境帳戶 (PROD)
```
用戶: prod-user
密碼: prod456
權限: prod.*, logs.prod.*, metrics.prod.*, alerts.*
JetStream 配額: 1GB 記憶體, 4GB 檔案, 1000 流, 10000 消費者
```

### 監控帳戶 (MONITORING) - 監控系統專用
```
用戶: monitor-user
密碼: monitor123
權限: 所有主題 (>), 系統主題 ($SYS.>), 系統請求 ($SYS.REQ.>)
用途: Prometheus 監控、日誌收集、健康檢查
JetStream 配額: 1GB 記憶體, 4GB 檔案, 1000 流, 10000 消費者
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
- **記憶體存儲**: 1GB
- **檔案存儲**: 4GB  
- **集群域**: nats-cluster
- **複製因子**: 3 (高可用性)
- **最大流數**: 1000
- **最大消費者數**: 10000

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

## 🛠️ 故障排除

### 常見問題

#### 1. 日誌目錄錯誤
**錯誤訊息**: `error opening file: open /data/logs/nats-node*.log: no such file or directory`

**解決方案**:
```bash
# 運行初始化腳本
./init-data-dirs.sh

# 重新啟動服務
docker compose down
docker compose up -d
```

#### 2. 集群節點無法連接
**檢查步驟**:
```bash
# 檢查容器狀態
docker compose ps

# 檢查節點日誌
docker compose logs nats-node1
docker compose logs nats-node2
docker compose logs nats-node3

# 檢查集群狀態
curl -s http://localhost:8222/varz | jq '.cluster'
```

#### 3. JetStream 功能異常
**檢查步驟**:
```bash
# 檢查 JetStream 狀態
curl -s http://localhost:8222/jsz | jq '.meta_cluster'

# 檢查 stream 創建
docker compose exec nats-box nats stream list

# 測試 JetStream 功能
docker compose exec nats-box nats stream add test-stream --subjects "test.*" --storage memory --replicas 3 --defaults
```

#### 4. 監控服務無法訪問
**檢查步驟**:
```bash
# 檢查 Prometheus 狀態
curl -s http://localhost:9090/-/healthy

# 檢查 Grafana 狀態
curl -s http://localhost:3000/api/health

# 檢查 NATS Surveyor
curl -s http://localhost:7777/metrics
```

### 日誌檢查

#### 查看特定節點日誌
```bash
# 查看 Node 1 日誌
docker compose logs nats-node1 -f

# 查看本地日誌文件
tail -f data/node1/logs/nats-node1.log
```

#### 查看所有服務日誌
```bash
# 查看所有服務日誌
docker compose logs -f

# 查看特定服務的錯誤日誌
docker compose logs nats-node1 | grep ERROR
```

### 性能調優

#### 記憶體使用優化
```bash
# 檢查記憶體使用情況
curl -s http://localhost:8222/varz | jq '.mem'

# 檢查 JetStream 記憶體使用
curl -s http://localhost:8222/jsz | jq '.memory'
```

#### 連接數監控
```bash
# 檢查當前連接數
curl -s http://localhost:8222/connz | jq '.connections | length'

# 檢查連接詳細信息
curl -s http://localhost:8222/connz | jq '.connections[] | {id, ip, port, subscriptions}'
```

## 📈 監控和儀表板

### Grafana 儀表板

訪問 http://localhost:3000 (admin/admin123) 查看以下儀表板：

1. **NATS Overview** - 集群概覽
2. **NATS Servers** - 服務器詳細信息
3. **JetStream Dashboard** - JetStream 監控
4. **NATS Surveyor** - 集群調查器
5. **Prometheus Exporter** - 指標導出器

### Prometheus 指標

主要指標端點：
- **NATS Surveyor**: http://localhost:7777/metrics
- **NATS Exporter**: http://localhost:7778/metrics

關鍵指標：
- `nats_core_mem_bytes` - 記憶體使用
- `nats_core_conn_count` - 連接數
- `nats_core_sub_count` - 訂閱數
- `nats_jetstream_messages_total` - JetStream 消息數

## 🔒 安全配置

### 集群認證
```bash
# 集群節點間認證
cluster_user: cluster_pass_123
```

### 客戶端認證
```bash
# 使用帳戶密碼連接
nats://username:password@localhost:4222

# 使用 TLS 連接（需要配置證書）
nats://localhost:4222?tls=true
```

### 權限控制
```bash
# 檢查帳戶權限
curl -s http://localhost:8222/accountz | jq '.accounts[] | {name, imports, exports}'
```

## 📝 開發指南

### 客戶端連接示例

#### Go 客戶端
```go
package main

import (
    "log"
    "github.com/nats-io/nats.go"
)

func main() {
    // 連接到集群
    nc, err := nats.Connect("nats://admin:nats123@localhost:4222")
    if err != nil {
        log.Fatal(err)
    }
    defer nc.Close()

    // 發布消息
    nc.Publish("test.subject", []byte("Hello NATS!"))

    // 訂閱消息
    nc.Subscribe("test.subject", func(msg *nats.Msg) {
        log.Printf("收到消息: %s", string(msg.Data))
    })

    // 保持連接
    select {}
}
```

#### JavaScript 客戶端
```javascript
const nats = require('nats');

// 連接到集群
const nc = nats.connect({
    servers: ['nats://admin:nats123@localhost:4222'],
    user: 'admin',
    pass: 'nats123'
});

// 發布消息
nc.publish('test.subject', 'Hello NATS!');

// 訂閱消息
nc.subscribe('test.subject', (msg) => {
    console.log('收到消息:', msg.data);
});
```

### JetStream 使用示例

#### 創建 Stream
```bash
# 創建持久化 stream
docker compose exec nats-box nats stream add orders --subjects "orders.*" --storage file --replicas 3 --defaults

# 創建記憶體 stream
docker compose exec nats-box nats stream add events --subjects "events.*" --storage memory --replicas 3 --defaults
```

#### 發布到 Stream
```bash
# 發布消息到 stream
docker compose exec nats-box nats pub orders.new "New order data"

# 查看 stream 信息
docker compose exec nats-box nats stream info orders
```

#### 創建 Consumer
```bash
# 創建 push consumer
docker compose exec nats-box nats consumer add orders order-processor --defaults

# 創建 pull consumer
docker compose exec nats-box nats consumer add orders order-puller --pull --defaults
```

## 🚀 部署到生產環境

### 環境變數配置
```bash
# 創建環境變數文件
cat > .env << EOF
NATS_CLUSTER_NAME=nats-cluster
NATS_CLUSTER_PORT=6222
NATS_CLIENT_PORT=4222
NATS_MONITOR_PORT=8222
JETSTREAM_MAX_MEMORY=1GB
JETSTREAM_MAX_STORAGE=4GB
EOF
```

### 健康檢查配置
```bash
# 添加到 docker-compose.yaml
healthcheck:
  test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:8222/varz"]
  interval: 15s
  timeout: 5s
  retries: 3
  start_period: 30s
```

### 日誌配置
```bash
# 配置日誌輪轉
log_file: "/data/logs/nats-node1.log"
log_size_limit: 100MB
debug: false
trace: false
logtime: true
```

## 📚 參考資源

- [NATS 官方文檔](https://docs.nats.io/)
- [JetStream 指南](https://docs.nats.io/nats-concepts/jetstream)
- [NATS CLI 工具](https://github.com/nats-io/natscli)
- [NATS Surveyor](https://github.com/nats-io/nats-surveyor)
- [Prometheus NATS Exporter](https://github.com/nats-io/prometheus-nats-exporter)

## 🤝 貢獻

歡迎提交 Issue 和 Pull Request 來改進這個項目！

## 📄 授權

本項目採用 MIT 授權條款。
