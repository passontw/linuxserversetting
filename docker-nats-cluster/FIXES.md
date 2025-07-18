# NATS 集群修復記錄

## 🔧 修復日期：2025-07-18

### 問題描述
NATS 集群節點無法啟動，出現以下錯誤：
```
nats-node1     | error opening file: open /data/logs/nats-node1.log: no such file or directory
nats-node2     | error opening file: open /data/logs/nats-node2.log: no such file or directory
nats-node3     | error opening file: open /data/logs/nats-node3.log: no such file or directory
```

### 根本原因
NATS 配置文件指定了日誌文件路徑 `/data/logs/nats-node*.log`，但 Docker 容器內沒有創建相應的目錄結構。

### 解決方案

#### 1. 修改 Docker Compose 配置
在 `docker-compose.yaml` 中修改 NATS 節點的啟動命令：

```yaml
# 修改前
command: ["-c", "/nats-server.conf"]

# 修改後
command: ["sh", "-c", "mkdir -p /data/logs && nats-server -c /nats-server.conf"]
```

#### 2. 創建初始化腳本
創建 `init-data-dirs.sh` 腳本來確保數據目錄結構存在：

```bash
#!/bin/bash
# 創建數據目錄結構
mkdir -p ./data/node1/logs
mkdir -p ./data/node1/jetstream
mkdir -p ./data/node2/logs
mkdir -p ./data/node2/jetstream
mkdir -p ./data/node3/logs
mkdir -p ./data/node3/jetstream
```

#### 3. 更新測試腳本
修改 `test-cluster.sh` 中的 JetStream 測試，使用 `--defaults` 標誌避免互動提示：

```bash
# 修改前
docker exec nats-box nats stream add test-stream --subjects "test.*" --storage memory --replicas 3

# 修改後
docker exec nats-box nats stream add test-stream --subjects "test.*" --storage memory --replicas 3 --defaults
```

### 驗證修復

#### 1. 運行初始化腳本
```bash
./init-data-dirs.sh
```

#### 2. 重啟服務
```bash
docker compose down
docker compose up -d
```

#### 3. 驗證集群功能
```bash
./test-cluster.sh
```

### 修復結果
✅ 所有 NATS 節點正常啟動  
✅ 日誌文件正確創建  
✅ JetStream 功能正常運作  
✅ 集群監控正常  
✅ 所有測試通過  

### 預防措施
1. 在部署前運行 `./init-data-dirs.sh` 腳本
2. 確保數據目錄具有適當的權限
3. 定期檢查日誌文件大小和輪轉
4. 監控集群健康狀態

### 相關文件
- `docker-compose.yaml` - 修改了啟動命令
- `init-data-dirs.sh` - 新增初始化腳本
- `test-cluster.sh` - 更新了測試邏輯
- `README.md` - 更新了使用說明和故障排除指南 