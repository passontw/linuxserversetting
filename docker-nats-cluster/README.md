# 🚀 NATS JetStream Cluster - 微服務訊息傳遞中心

高可用性的 NATS JetStream 集群配置，專為微服務架構設計，支援進階 Access Control、多租戶隔離、Web UI 監控和 Prometheus 指標。

## 📋 架構概覽

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   NATS Node 1   │    │   NATS Node 2   │    │   NATS Node 3   │
│   Port: 4222    │◄──►│   Port: 4223    │◄──►│   Port: 4224    │
│ Monitor: 8222   │    │ Monitor: 8223   │    │ Monitor: 8224   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ NATS Surveyor   │
                    │ Web UI: 7777    │
                    └─────────────────┘
```

## ✨ 主要特性

### 🔧 核心功能
- **3 節點高可用集群** - 確保服務可靠性
- **JetStream 啟用** - 每節點 4GB 持久化存儲
- **資料持久化** - 配置檔案和數據的完整持久化
- **專用 Docker 網路** - 網路隔離和安全性

### 🔐 安全 & 權限控制
- **進階 Access Control** - Account 隔離 + Subject 權限 + Rate Limiting
- **多租戶隔離** - 開發/生產/微服務環境完全隔離
- **細粒度權限** - 按微服務精確控制訊息權限
- **Rate Limiting** - 防止服務濫用

### 📊 監控 & 管理
- **NATS Surveyor** - Web UI 監控和管理介面
- **Prometheus Metrics** - 完整的監控指標支援
- **健康檢查** - 自動健康狀態檢測
- **詳細日誌** - 結構化日誌記錄

## 🚀 快速開始

### 1. 啟動服務
```bash
# 進入專案目錄
cd docker-nats-cluster

# 啟動所有服務
docker-compose up -d

# 檢查服務狀態
docker-compose ps

# 查看日誌
docker-compose logs -f
```

### 2. 驗證集群狀態
```bash
# 檢查集群狀態
curl http://localhost:8222/routez

# 檢查 JetStream 狀態
curl http://localhost:8222/jsz
```

### 3. 存取 Web UI
- **NATS Surveyor**: http://localhost:7777
- **節點監控**: 
  - Node 1: http://localhost:8222
  - Node 2: http://localhost:8223  
  - Node 3: http://localhost:8224

## 🔑 預設帳號資訊

### 管理員帳戶
```
Username: admin
Password: nats123
權限: 完整存取所有主題
用途: 系統管理和維護
```

### 開發環境帳戶
```
Username: dev-user
Password: dev123
權限: dev.*, logs.dev.*, metrics.dev.*
限制: 50 訂閱, 1MB 訊息, 100 msgs/sec
```

### 生產環境帳戶
```
Username: prod-user
Password: prod456
權限: prod.*, logs.prod.*, metrics.prod.*, alerts.*
限制: 100 訂閱, 2MB 訊息, 500 msgs/sec
```

### 微服務帳戶

#### 用戶服務
```
Username: user-service
Password: user789
權限: services.user.*, events.user.*, notifications.user.*
限制: 30 訂閱, 512KB 訊息, 200 msgs/sec
```

#### 訂單服務
```
Username: order-service
Password: order789
權限: services.order.*, events.order.*, notifications.order.*
限制: 30 訂閱, 1MB 訊息, 300 msgs/sec
```

#### 支付服務
```
Username: payment-service
Password: payment789
權限: services.payment.*, events.payment.*, notifications.payment.*
限制: 20 訂閱, 512KB 訊息, 150 msgs/sec
```

#### 通知服務
```
Username: notification-service
Password: notify789
權限: notifications.send.*, events.notification.*
限制: 50 訂閱, 256KB 訊息, 100 msgs/sec
```

### 監控帳戶
```
Username: monitor-user
Password: monitor123
權限: 完整監控權限 (metrics.*, logs.*, health.*, $SYS.*)
限制: 200 訂閱, 1MB 訊息, 1000 msgs/sec
```

## 🔌 連接資訊

### 客戶端連接
```bash
# 單節點連接
nats://admin:nats123@localhost:4222

# 集群連接（推薦）
nats://admin:nats123@localhost:4222,localhost:4223,localhost:4224
```

### 程式碼範例 (Go)
```go
package main

import (
    "log"
    "github.com/nats-io/nats.go"
)

func main() {
    // 連接到 NATS 集群
    nc, err := nats.Connect(
        "nats://user-service:user789@localhost:4222,localhost:4223,localhost:4224",
        nats.MaxReconnects(5),
        nats.ReconnectWait(2*time.Second),
    )
    if err != nil {
        log.Fatal(err)
    }
    defer nc.Close()

    // 發布訊息
    err = nc.Publish("services.user.created", []byte("User created event"))
    if err != nil {
        log.Fatal(err)
    }

    // 訂閱訊息
    sub, err := nc.Subscribe("events.auth.*", func(msg *nats.Msg) {
        log.Printf("Received: %s", string(msg.Data))
    })
    if err != nil {
        log.Fatal(err)
    }
    defer sub.Unsubscribe()

    // 等待訊息
    select {}
}
```

## 📊 監控端點

### Prometheus Metrics
```bash
# 各節點的 Prometheus 指標
curl http://localhost:8222/metrics  # Node 1
curl http://localhost:8223/metrics  # Node 2  
curl http://localhost:8224/metrics  # Node 3
```

### 監控 API
```bash
# 伺服器統計
curl http://localhost:8222/varz

# 連接資訊
curl http://localhost:8222/connz

# 路由資訊
curl http://localhost:8222/routez

# 訂閱資訊
curl http://localhost:8222/subsz

# JetStream 統計
curl http://localhost:8222/jsz

# 健康檢查
curl http://localhost:8222/healthz
```

## 🔒 TLS 加密設定

### 1. 生成證書
```bash
# 建立證書目錄
mkdir -p certs

# 生成 CA 私鑰
openssl genrsa -out certs/ca.key 4096

# 生成 CA 證書
openssl req -new -x509 -days 365 -key certs/ca.key -out certs/ca.crt \
    -subj "/C=TW/ST=Taiwan/L=Taipei/O=NATS-Cluster/CN=NATS-CA"

# 生成伺服器私鑰
openssl genrsa -out certs/server.key 4096

# 生成伺服器證書請求
openssl req -new -key certs/server.key -out certs/server.csr \
    -subj "/C=TW/ST=Taiwan/L=Taipei/O=NATS-Cluster/CN=nats-server"

# 生成伺服器證書
openssl x509 -req -days 365 -in certs/server.csr -CA certs/ca.crt \
    -CAkey certs/ca.key -CAcreateserial -out certs/server.crt

# 生成客戶端私鑰
openssl genrsa -out certs/client.key 4096

# 生成客戶端證書請求
openssl req -new -key certs/client.key -out certs/client.csr \
    -subj "/C=TW/ST=Taiwan/L=Taipei/O=NATS-Cluster/CN=nats-client"

# 生成客戶端證書
openssl x509 -req -days 365 -in certs/client.csr -CA certs/ca.crt \
    -CAkey certs/ca.key -CAcreateserial -out certs/client.crt
```

### 2. 修改配置檔案
在每個節點的 `.conf` 檔案中啟用 TLS：

```bash
# 取消註解 TLS 配置區塊
tls {
    cert_file: "/etc/nats/certs/server.crt"
    key_file: "/etc/nats/certs/server.key" 
    ca_file: "/etc/nats/certs/ca.crt"
    verify: true
    timeout: 5
}
```

### 3. 更新 Docker Compose
```yaml
volumes:
  - ./certs:/etc/nats/certs:ro
```

### 4. 客戶端 TLS 連接
```go
// TLS 連接範例
opts := []nats.Option{
    nats.ClientCert("./certs/client.crt", "./certs/client.key"),
    nats.RootCAs("./certs/ca.crt"),
}

nc, err := nats.Connect("tls://admin:nats123@localhost:4222", opts...)
```

## 🎛️ 進階配置

### JetStream 管理
```bash
# 建立 Stream
nats stream create ORDERS --subjects "orders.*" --storage file --replicas 3

# 建立 Consumer
nats consumer create ORDERS ORDER_PROCESSOR --pull --deliver all

# 發布訊息到 Stream
nats pub orders.created '{"order_id": "12345", "amount": 99.99}'

# 從 Consumer 拉取訊息
nats consumer next ORDERS ORDER_PROCESSOR
```

### 效能調校
```bash
# 調整 JetStream 記憶體限制
# 在 nats-nodeX.conf 中:
jetstream {
    max_memory_store: 2GB
    max_file_store: 8GB
}

# 調整連接限制
max_connections: 2000
max_payload: 32MB
```

## 🔧 常用命令

### 服務管理
```bash
# 啟動服務
docker-compose up -d

# 停止服務
docker-compose down

# 重新啟動服務
docker-compose restart

# 查看服務狀態
docker-compose ps

# 查看即時日誌
docker-compose logs -f

# 查看特定服務日誌
docker-compose logs -f nats-node1
```

### 偵錯與維護
```bash
# 進入容器
docker-compose exec nats-node1 sh

# 檢查配置
docker-compose exec nats-node1 cat /nats-server.conf

# 清理資料（謹慎使用）
docker-compose down -v
```

## 📁 資料夾結構

```
docker-nats-cluster/
├── docker-compose.yaml          # Docker Compose 配置
├── config/                      # 配置檔案目錄
│   ├── accounts.conf           # Account 和權限配置
│   ├── nats-node1.conf         # 節點 1 配置
│   ├── nats-node2.conf         # 節點 2 配置
│   └── nats-node3.conf         # 節點 3 配置
├── data/                       # 資料持久化目錄
│   ├── node1/                  # 節點 1 資料
│   │   ├── jetstream/          # JetStream 資料
│   │   └── logs/               # 日誌檔案
│   ├── node2/                  # 節點 2 資料
│   │   ├── jetstream/
│   │   └── logs/
│   └── node3/                  # 節點 3 資料
│       ├── jetstream/
│       └── logs/
├── certs/                      # TLS 證書目錄 (選用)
└── README.md                   # 本說明文件
```

## 🚨 注意事項

### 安全考量
1. **生產環境** 務必修改所有預設密碼
2. **TLS 加密** 生產環境建議啟用 TLS
3. **防火牆** 適當設定防火牆規則
4. **網路隔離** 使用專用網路進行隔離

### 效能最佳化
1. **儲存效能** 使用 SSD 以提升 JetStream 效能
2. **記憶體配置** 根據訊息量調整記憶體限制
3. **網路頻寬** 確保足夠的網路頻寬
4. **監控告警** 設定適當的監控告警

### 備份策略
1. **配置備份** 定期備份 config/ 目錄
2. **資料備份** 定期備份 data/ 目錄
3. **版本控制** 將配置檔案納入版本控制
4. **災難復原** 建立完整的災難復原程序

## 📞 支援與協助

### 故障排除
1. **服務無法啟動** 檢查連接埠是否被占用
2. **集群無法形成** 檢查網路連接和防火牆設定
3. **認證失敗** 確認帳號密碼正確
4. **儲存空間不足** 檢查磁碟空間和 JetStream 限制

### 日誌分析
```bash
# 查看錯誤日誌
docker-compose logs nats-node1 | grep ERROR

# 查看連接日誌
docker-compose logs nats-node1 | grep "Client connection"

# 查看集群日誌
docker-compose logs nats-node1 | grep "Route connection"
```

### 社群資源
- [NATS 官方文檔](https://docs.nats.io/)
- [JetStream 指南](https://docs.nats.io/jetstream)
- [NATS GitHub](https://github.com/nats-io)

---

🎉 **恭喜！您已成功設定 NATS JetStream 集群！**

現在您可以開始使用這個強大的微服務訊息傳遞中心來建構您的分散式系統。 