#!/bin/bash

# =================================================================
# NATS JetStream Cluster - 測試腳本
# =================================================================
# 此腳本用於驗證 NATS 集群的配置和功能
# 使用方法: ./test-cluster.sh
# =================================================================

set -e  # 遇到錯誤時停止執行

echo "🚀 NATS JetStream Cluster 測試開始..."
echo "=================================="

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 測試函數
test_health() {
    local node=$1
    local port=$2
    echo -e "${BLUE}檢查 Node $node 健康狀態...${NC}"
    
    if curl -s -f "http://localhost:$port/healthz" > /dev/null; then
        echo -e "${GREEN}✅ Node $node 健康狀態: OK${NC}"
        return 0
    else
        echo -e "${RED}❌ Node $node 健康狀態: FAILED${NC}"
        return 1
    fi
}

test_cluster_info() {
    local port=$1
    echo -e "${BLUE}檢查集群資訊...${NC}"
    
    # 使用 jq 來美化 JSON 輸出，如果沒有 jq 則使用原始輸出
    if command -v jq &> /dev/null; then
        curl -s "http://localhost:$port/routez" | jq '.routes | length' > /dev/null
        local route_count=$(curl -s "http://localhost:$port/routez" | jq '.routes | length')
        echo -e "${GREEN}✅ 集群路由數量: $route_count${NC}"
    else
        echo -e "${YELLOW}⚠️  建議安裝 jq 以獲得更好的 JSON 輸出格式${NC}"
        curl -s "http://localhost:$port/routez" | grep -o '"routes":\[[^]]*\]' > /dev/null
        echo -e "${GREEN}✅ 集群路由配置正常${NC}"
    fi
}

test_jetstream() {
    local port=$1
    echo -e "${BLUE}檢查 JetStream 狀態...${NC}"
    
    local js_response=$(curl -s "http://localhost:$port/jsz")
    
    if echo "$js_response" | grep -q '"enabled":true'; then
        echo -e "${GREEN}✅ JetStream 已啟用${NC}"
        
        # 檢查儲存配置
        if command -v jq &> /dev/null; then
            local memory_store=$(echo "$js_response" | jq '.config.max_memory // "N/A"')
            local file_store=$(echo "$js_response" | jq '.config.max_file // "N/A"')
            echo -e "${GREEN}📊 記憶體存儲限制: $memory_store${NC}"
            echo -e "${GREEN}📊 檔案存儲限制: $file_store${NC}"
        fi
    else
        echo -e "${RED}❌ JetStream 未啟用${NC}"
        return 1
    fi
}

# 主要測試流程
echo "🔍 1. 檢查 Docker 服務狀態..."
if ! docker-compose ps | grep -q "Up"; then
    echo -e "${RED}❌ Docker 服務未啟動，請先執行: docker-compose up -d${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker 服務正在運行${NC}"
echo ""

echo "🏥 2. 健康檢查..."
test_health "1" "8222"
test_health "2" "8223"  
test_health "3" "8224"
echo ""

echo "🌐 3. 集群狀態檢查..."
test_cluster_info "8222"
echo ""

echo "💾 4. JetStream 狀態檢查..."
test_jetstream "8222"
echo ""

echo "🖥️  5. 檢查 NATS Surveyor..."
if curl -s -f "http://localhost:7777" > /dev/null; then
    echo -e "${GREEN}✅ NATS Surveyor Web UI 正常運行${NC}"
    echo -e "${BLUE}🌐 Web UI 地址: http://localhost:7777${NC}"
else
    echo -e "${RED}❌ NATS Surveyor Web UI 無法存取${NC}"
fi
echo ""

echo "📊 6. Prometheus Metrics 檢查..."
for i in 1 2 3; do
    port=$((8220 + i + 1))
    if curl -s "http://localhost:$port/metrics" | grep -q "nats_"; then
        echo -e "${GREEN}✅ Node $i Prometheus metrics 可用${NC}"
    else
        echo -e "${RED}❌ Node $i Prometheus metrics 不可用${NC}"
    fi
done
echo ""

echo "🔐 7. 帳戶權限測試 (需要 nats CLI)..."
if command -v nats &> /dev/null; then
    echo -e "${BLUE}測試管理員帳戶連接...${NC}"
    if nats --server="nats://admin:nats123@localhost:4222" server info > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 管理員帳戶連接成功${NC}"
    else
        echo -e "${RED}❌ 管理員帳戶連接失敗${NC}"
    fi
    
    echo -e "${BLUE}測試開發帳戶連接...${NC}"
    if nats --server="nats://dev-user:dev123@localhost:4222" server info > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 開發帳戶連接成功${NC}"
    else
        echo -e "${RED}❌ 開發帳戶連接失敗${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  未安裝 nats CLI，跳過權限測試${NC}"
    echo -e "${YELLOW}   安裝方法: https://github.com/nats-io/natscli${NC}"
fi
echo ""

echo "📋 8. 連接資訊摘要..."
echo -e "${BLUE}=================================${NC}"
echo -e "${GREEN}🔗 客戶端連接端點:${NC}"
echo -e "   Node 1: nats://localhost:4222"
echo -e "   Node 2: nats://localhost:4223"
echo -e "   Node 3: nats://localhost:4224"
echo ""
echo -e "${GREEN}🖥️  管理介面:${NC}"
echo -e "   NATS Surveyor: http://localhost:7777"
echo -e "   Node 1 Monitor: http://localhost:8222"
echo -e "   Node 2 Monitor: http://localhost:8223"
echo -e "   Node 3 Monitor: http://localhost:8224"
echo ""
echo -e "${GREEN}📊 Prometheus Metrics:${NC}"
echo -e "   Node 1: http://localhost:8222/metrics"
echo -e "   Node 2: http://localhost:8223/metrics"
echo -e "   Node 3: http://localhost:8224/metrics"
echo ""

echo -e "${GREEN}🎉 測試完成！${NC}"
echo -e "${BLUE}如需更多資訊，請查看 README.md${NC}" 