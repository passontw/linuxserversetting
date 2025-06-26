# NATS JetStream 監控指南

## 📊 監控架構概覽

本項目整合了完整的 NATS JetStream 監控解決方案，包含：

### 指標收集
- **NATS Surveyor** (port 7777): 提供約 45 個 NATS 和 JetStream 指標
- **NATS Prometheus Exporter** (port 7778): 額外的技術指標
- **Prometheus** (port 9090): 指標存儲和查詢引擎

### 日誌聚合
- **Loki** (port 3100): 集中式日誌存儲
- **Promtail**: 自動收集 Docker 容器日誌

### 視覺化
- **Grafana** (port 3000): 統一的監控儀表板介面

---

## 🚀 快速開始

### 1. 啟動完整監控堆疊
```bash
# 啟動所有服務
docker compose up -d

# 檢查服務狀態
./test-cluster.sh
```

### 2. 存取監控介面

#### Grafana 儀表板
- **URL**: http://localhost:3000
- **預設帳號**: admin / admin123
- **包含儀表板**:
  - `NATS JetStream 集群監控`: 主要的 JetStream 指標
  - `NATS 日誌分析`: 日誌查詢和分析
  - 官方 NATS 儀表板 (如果可用)

#### Prometheus
- **URL**: http://localhost:9090
- **用途**: 原始指標查詢和除錯

#### Loki API
- **URL**: http://localhost:3100
- **用途**: 直接日誌查詢 API

---

## 📈 Grafana 儀表板詳解

### NATS JetStream 集群監控

#### 主要指標面板
1. **JetStream 狀態**: 顯示每個節點的 JetStream 啟用狀態
2. **JetStream 流統計**: 當前流的數量和分布
3. **記憶體和存儲使用**: JetStream 記憶體和存儲用量
4. **NATS 連接數**: 各節點的活躍連接統計
5. **訊息吞吐量**: 每秒入站和出站訊息數

#### 使用技巧
- 使用時間範圍選擇器調整監控視窗
- 點擊圖例可隱藏/顯示特定節點
- 滑鼠懸停查看詳細數值

### NATS 日誌分析

#### 日誌面板說明
1. **日誌計數**: 每5分鐘的日誌數量統計
2. **日誌級別分布**: ERROR、WARN、INFO、DEBUG 分布
3. **最新日誌表格**: 結構化的最新日誌條目
4. **日誌流**: 即時日誌串流顯示

#### 日誌查詢範例
```logql
# 查看所有 NATS 日誌
{job="nats"}

# 查看錯誤日誌
{job="nats"} |~ "\\[ERROR\\]"

# 查看特定容器日誌
{job="nats", container_name="nats-node1"}

# 查看 JetStream 相關日誌
{job="nats"} |~ "(?i)jetstream"
```

---

## 🔍 進階監控操作

### 1. 自定義告警

#### 在 Prometheus 中設定告警規則
```yaml
# alerting_rules.yml
groups:
  - name: nats.rules
    rules:
      - alert: NATSNodeDown
        expr: up{job="nats-surveyor"} == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "NATS node is down"
          
      - alert: JetStreamHighMemoryUsage
        expr: nats_jetstream_memory / (1024*1024*1024) > 0.8
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "JetStream memory usage is high"
```

### 2. 效能指標分析

#### 關鍵指標解讀
- **nats_connz_total**: 總連接數
- **nats_jetstream_enabled**: JetStream 啟用狀態
- **nats_jetstream_memory**: JetStream 記憶體使用
- **nats_jetstream_streams**: 流數量
- **nats_varz_in_msgs_total**: 總入站訊息數
- **nats_varz_out_msgs_total**: 總出站訊息數

#### 效能最佳化建議
1. **監控連接數**: 超過 1000 個連接時考慮負載均衡
2. **記憶體使用**: JetStream 記憶體使用超過 80% 時增加資源
3. **訊息積壓**: 監控流中的未處理訊息數量
4. **錯誤率**: ERROR 日誌比例超過 1% 時需要調查

### 3. 故障排除

#### 常見問題診斷

**JetStream 未啟用**
```bash
# 檢查 JetStream 配置
docker compose exec nats-box nats account info

# 檢查集群狀態
docker compose exec nats-box nats server info
```

**連接問題**
```bash
# 測試連接
docker compose exec nats-box nats pub test.subject "hello world"
docker compose exec nats-box nats sub test.subject
```

**記憶體問題**
```bash
# 檢查記憶體使用
docker compose exec nats-box nats server report jetstream
```

---

## 🔧 配置調整

### 調整監控間隔
編輯 `monitoring/prometheus/prometheus.yml`:
```yaml
global:
  scrape_interval: 30s  # 改為 15s 以提高精度
```

### 日誌保留策略
編輯 `monitoring/loki/loki-config.yml`:
```yaml
limits_config:
  retention_period: 168h  # 7 天
  retention_deletes_enabled: true
```

### Grafana 資料來源
自動配置的資料來源：
- **Prometheus**: http://prometheus:9090
- **Loki**: http://loki:3100

---

## 📊 指標參考

### NATS Surveyor 提供的指標類別
1. **伺服器指標**: CPU、記憶體、連接數
2. **JetStream 指標**: 流、消費者、存儲
3. **集群指標**: 路由、領導者選舉
4. **帳戶指標**: 使用者、權限、配額

### 日誌標籤
- `job`: nats, monitoring
- `container_name`: nats-node1, nats-node2, nats-node3
- `log_level`: INFO, WARN, ERROR, DEBUG
- `service`: nats, monitoring

---

## 🚨 監控最佳實踐

### 1. 定期檢查項目
- [ ] 每日檢查錯誤日誌
- [ ] 每週檢查效能趨勢
- [ ] 每月檢查資源使用情況

### 2. 備份策略
```bash
# 備份 Prometheus 資料
docker run --rm -v prometheus-data:/source alpine tar czf /backup/prometheus-$(date +%Y%m%d).tar.gz /source

# 備份 Grafana 配置
docker run --rm -v grafana-data:/source alpine tar czf /backup/grafana-$(date +%Y%m%d).tar.gz /source
```

### 3. 安全考量
- 在生產環境中修改預設密碼
- 限制 Grafana 和 Prometheus 的網路存取
- 定期更新容器映像

---

## 📚 更多資源

### 官方文檔
- [NATS 監控指南](https://docs.nats.io/running-a-nats-service/nats_admin/monitoring)
- [JetStream 監控](https://docs.nats.io/running-a-nats-service/nats_admin/jetstream_admin/monitoring)
- [Grafana 文檔](https://grafana.com/docs/)
- [Prometheus 文檔](https://prometheus.io/docs/)

### 相關工具
- [NATS CLI](https://github.com/nats-io/natscli): 命令列管理工具
- [NATS Top](https://github.com/nats-io/nats-top): 即時監控工具
- [NATS Bench](https://github.com/nats-io/nats.go): 效能測試工具

---

## ❓ 常見問題

**Q: 為什麼看不到 JetStream 指標？**
A: 確保 JetStream 已啟用且有活躍的流。使用 `nats stream ls` 檢查。

**Q: Loki 查詢很慢怎麼辦？**
A: 縮小時間範圍，使用更具體的標籤過濾器。

**Q: 如何添加自定義儀表板？**
A: 將 JSON 檔案放到 `monitoring/grafana/dashboards/` 目錄並重啟 Grafana。

**Q: 監控資料佔用空間過大？**
A: 調整 Prometheus 和 Loki 的保留策略，定期清理舊資料。 