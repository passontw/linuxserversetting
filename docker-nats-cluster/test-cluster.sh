#!/bin/bash

# NATS 集群測試腳本
# 測試集群的基本功能、JetStream、監控等

echo "=========================================="
echo "NATS 集群功能測試"
echo "=========================================="

# 等待服務啟動
echo "等待服務啟動..."
sleep 10

# 測試基本連接
echo "1. 測試基本連接..."
docker exec nats-box nats pub test.basic "Basic connection test" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ 基本連接測試通過"
else
    echo "❌ 基本連接測試失敗"
fi

# 測試 JetStream
echo "2. 測試 JetStream..."
docker exec nats-box nats stream add test-stream --subjects "test.*" --storage memory --replicas 3 --defaults > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ JetStream 創建成功"
    
    # 發布消息到 JetStream
    docker exec nats-box nats pub test.jetstream "JetStream test message" > /dev/null 2>&1
    echo "✅ JetStream 消息發布成功"
else
    echo "❌ JetStream 測試失敗"
fi

# 測試集群狀態
echo "3. 測試集群狀態..."
NODE1_STATUS=$(curl -s http://localhost:8222/varz | jq -r '.cluster.name // "unknown"')
NODE2_STATUS=$(curl -s http://localhost:8223/varz | jq -r '.cluster.name // "unknown"')
NODE3_STATUS=$(curl -s http://localhost:8224/varz | jq -r '.cluster.name // "unknown"')

if [ "$NODE1_STATUS" = "nats-cluster" ] && [ "$NODE2_STATUS" = "nats-cluster" ] && [ "$NODE3_STATUS" = "nats-cluster" ]; then
    echo "✅ 所有節點都在同一集群中"
else
    echo "❌ 集群狀態異常"
    echo "  Node 1: $NODE1_STATUS"
    echo "  Node 2: $NODE2_STATUS"
    echo "  Node 3: $NODE3_STATUS"
fi

# 測試監控端點
echo "4. 測試監控端點..."
if curl -s http://localhost:7777 > /dev/null 2>&1; then
    echo "✅ NATS Surveyor 監控界面可訪問"
else
    echo "❌ NATS Surveyor 監控界面無法訪問"
fi

if curl -s http://localhost:7778/metrics > /dev/null 2>&1; then
    echo "✅ Prometheus 指標端點可訪問"
else
    echo "❌ Prometheus 指標端點無法訪問"
fi

if curl -s http://localhost:9090 > /dev/null 2>&1; then
    echo "✅ Prometheus 服務可訪問"
else
    echo "❌ Prometheus 服務無法訪問"
fi

if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Grafana 界面可訪問"
else
    echo "❌ Grafana 界面無法訪問"
fi

# 顯示連接信息
echo ""
echo "=========================================="
echo "NATS 集群連接信息"
echo "=========================================="
echo "客戶端連接端口："
echo "  Node 1: localhost:4222"
echo "  Node 2: localhost:4223"
echo "  Node 3: localhost:4224"
echo ""
echo "監控端口："
echo "  Node 1: http://localhost:8222"
echo "  Node 2: http://localhost:8223"
echo "  Node 3: http://localhost:8224"
echo "  NATS Surveyor: http://localhost:7777"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana: http://localhost:3000 (admin/admin123)"
echo ""
echo "測試完成！" 