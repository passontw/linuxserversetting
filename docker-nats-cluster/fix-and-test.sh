#!/bin/bash

# =================================================================
# NATS JetStream Cluster - 問題修復與驗證腳本 (改進版)
# =================================================================
# 此腳本用於修復已知問題並驗證修復效果
# 使用方法: ./fix-and-test.sh
# =================================================================

set -e

echo "🔧 NATS JetStream Cluster 問題修復與測試開始..."
echo "============================================"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 1. 停止現有服務
echo -e "${BLUE}1. 停止現有服務...${NC}"
docker compose down
sleep 5

# 2. 清理舊的數據 (可選)
echo -e "${BLUE}2. 清理舊數據 (可選，按 Enter 跳過)...${NC}"
read -p "是否清理舊數據？ (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}清理數據目錄...${NC}"
    sudo rm -rf data/
    docker volume rm $(docker volume ls -q | grep nats) 2>/dev/null || true
fi

# 3. 重新啟動服務
echo -e "${BLUE}3. 重新啟動服務...${NC}"
docker compose up -d

# 4. 等待服務啟動 (增加等待時間)
echo -e "${BLUE}4. 等待服務初始化 (60秒)...${NC}"
for i in {1..60}; do
    echo -n "."
    sleep 1
done
echo ""

# 5. 檢查服務狀態
echo -e "${BLUE}5. 檢查服務狀態...${NC}"
docker compose ps

# 測試函數
test_service() {
    local service=$1
    local url=$2
    local timeout=${3:-15}
    
    echo -e "${BLUE}測試 $service...${NC}"
    
    for i in $(seq 1 $timeout); do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service: 正常運行${NC}"
            return 0
        fi
        echo -n "."
        sleep 1
    done
    
    echo -e "${RED}❌ $service: 連接失敗${NC}"
    return 1
}

test_nats_node() {
    local node=$1
    local port=$2
    echo -e "${BLUE}測試 NATS Node $node...${NC}"
    
    if curl -s -f "http://localhost:$port/varz" > /dev/null; then
        local jetstream_status=$(curl -s "http://localhost:$port/jsz" 2>/dev/null | grep -o '"enabled":[^,]*' | head -1)
        if [[ $jetstream_status == *"true"* ]]; then
            echo -e "${GREEN}✅ Node $node: JetStream 已啟用${NC}"
        else
            echo -e "${YELLOW}⚠️  Node $node: JetStream 未啟用或正在初始化${NC}"
        fi
        
        # 檢查集群狀態
        local routes=$(curl -s "http://localhost:$port/routez" 2>/dev/null | grep -o '"num_routes":[^,]*' | head -1)
        echo -e "${BLUE}   集群路由: $routes${NC}"
        
        return 0
    else
        echo -e "${RED}❌ Node $node: 連接失敗${NC}"
        return 1
    fi
}

# 6. 逐一測試服務
echo -e "${BLUE}6. 服務健康檢查...${NC}"

# 測試 NATS 節點 (給更多時間)
test_nats_node "1" "8222"
test_nats_node "2" "8223"
test_nats_node "3" "8224"

# 測試監控服務
test_service "NATS Surveyor" "http://localhost:7777/metrics" 20
test_service "NATS Exporter" "http://localhost:7778/metrics" 15
test_service "Prometheus" "http://localhost:9090/-/healthy" 20
test_service "Loki" "http://localhost:3100/ready" 20
test_service "Grafana" "http://localhost:3000/api/health" 25

# 7. 測試 NATS 連接
echo -e "${BLUE}7. 測試 NATS 帳戶連接...${NC}"

if command -v nats &> /dev/null; then
    echo -e "${BLUE}測試管理員帳戶...${NC}"
    if timeout 15 nats --server="nats://admin:nats123@localhost:4222" server info > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 管理員帳戶連接成功${NC}"
    else
        echo -e "${RED}❌ 管理員帳戶連接失敗${NC}"
    fi
    
    echo -e "${BLUE}測試監控帳戶...${NC}"
    if timeout 15 nats --server="nats://monitor-user:monitor123@localhost:4222" server info > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 監控帳戶連接成功${NC}"
    else
        echo -e "${RED}❌ 監控帳戶連接失敗${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  未安裝 nats CLI，跳過連接測試${NC}"
    echo -e "${BLUE}💡 可使用 Docker 內的 nats CLI:${NC}"
    echo "   docker compose exec nats-box nats --server='nats://admin:nats123@nats-node1:4222' server info"
fi

# 8. 檢查日誌錯誤
echo -e "${BLUE}8. 檢查最近的錯誤日誌...${NC}"

echo -e "${YELLOW}檢查 Loki 日誌...${NC}"
if docker compose logs loki --tail=5 | grep -i "error\|failed"; then
    echo -e "${RED}⚠️  Loki 仍有錯誤日誌${NC}"
else
    echo -e "${GREEN}✅ Loki 日誌正常${NC}"
fi

echo -e "${YELLOW}檢查 NATS Surveyor 日誌...${NC}"
if docker compose logs nats-surveyor --tail=5 | grep -i "expected.*servers\|timeout\|failed\|error"; then
    echo -e "${RED}⚠️  NATS Surveyor 仍有問題${NC}"
else
    echo -e "${GREEN}✅ NATS Surveyor 日誌正常${NC}"
fi

echo -e "${YELLOW}檢查 NATS 節點日誌...${NC}"
if docker compose logs nats-node1 nats-node2 nats-node3 --tail=3 | grep -i "error\|failed"; then
    echo -e "${RED}⚠️  NATS 節點有錯誤${NC}"
else
    echo -e "${GREEN}✅ NATS 節點日誌正常${NC}"
fi

# 9. 顯示訪問資訊
echo -e "${BLUE}9. 修復完成！訪問資訊：${NC}"
echo -e "${GREEN}🔗 服務端點:${NC}"
echo "   NATS Nodes: localhost:4222, localhost:4223, localhost:4224"
echo "   Grafana: http://localhost:3000 (admin/admin123)"
echo "   Prometheus: http://localhost:9090"
echo "   NATS Surveyor: http://localhost:7777/metrics"
echo ""
echo -e "${GREEN}🔐 測試連接指令:${NC}"
echo "   docker compose exec nats-box nats --server='nats://admin:nats123@nats-node1:4222' server info"
echo "   docker compose exec nats-box nats --server='nats://monitor-user:monitor123@nats-node1:4222' server info"
echo ""
echo -e "${GREEN}📊 監控資源:${NC}"
echo "   所有 Prometheus 指標: http://localhost:7777/metrics"
echo "   Grafana 儀表板: http://localhost:3000/dashboards"
echo ""
echo -e "${GREEN}🔧 如果還有問題，檢查:${NC}"
echo "   docker compose logs -f  # 查看即時日誌"
echo "   docker compose ps       # 查看服務狀態"

echo -e "${GREEN}🎉 修復和測試完成！${NC}" 