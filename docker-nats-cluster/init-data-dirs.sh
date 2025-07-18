#!/bin/bash

# NATS Cluster 數據目錄初始化腳本
# 確保所有必要的目錄結構都存在

echo "正在創建 NATS 集群數據目錄..."

# 創建數據目錄結構
mkdir -p ./data/node1/logs
mkdir -p ./data/node1/jetstream
mkdir -p ./data/node2/logs
mkdir -p ./data/node2/jetstream
mkdir -p ./data/node3/logs
mkdir -p ./data/node3/jetstream

# 設置適當的權限
chmod 755 ./data/node1/logs
chmod 755 ./data/node1/jetstream
chmod 755 ./data/node2/logs
chmod 755 ./data/node2/jetstream
chmod 755 ./data/node3/logs
chmod 755 ./data/node3/jetstream

echo "數據目錄創建完成！"
echo "目錄結構："
echo "  ./data/node1/logs/     - Node 1 日誌目錄"
echo "  ./data/node1/jetstream/ - Node 1 JetStream 數據"
echo "  ./data/node2/logs/     - Node 2 日誌目錄"
echo "  ./data/node2/jetstream/ - Node 2 JetStream 數據"
echo "  ./data/node3/logs/     - Node 3 日誌目錄"
echo "  ./data/node3/jetstream/ - Node 3 JetStream 數據" 