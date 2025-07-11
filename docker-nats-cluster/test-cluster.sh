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
    
    if curl -s -f "http://localhost:$port/varz" > /dev/null; then
        echo -e "${GREEN}✅ Node $node 基本服務: OK${NC}"
        
        # 檢查 JetStream 狀態
        local healthz_response=$(curl -s "http://localhost:$port/healthz")
        if echo "$healthz_response" | grep -q '"status":"ok"'; then
            echo -e "${GREEN}✅ Node $node JetStream: Ready${NC}"
        elif echo "$healthz_response" | grep -q "meta leader"; then
            echo -e "${YELLOW}⚠️  Node $node JetStream: 等待 meta leader 選舉${NC}"
        else
            echo -e "${YELLOW}⚠️  Node $node JetStream: 初始化中${NC}"
        fi
        return 0
    else
        echo -e "${RED}❌ Node $node 基本服務: FAILED${NC}"
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
    
    if echo "$js_response" | grep -q '"config"'; then
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
if ! docker compose ps | grep -q "Up"; then
    echo -e "${RED}❌ Docker 服務未啟動，請先執行: docker compose up -d${NC}"
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

echo "🖥️  5. 檢查監控服務..."

# 檢查 NATS Surveyor (Prometheus Exporter)
if curl -s -f "http://localhost:7777/metrics" > /dev/null; then
    echo -e "${GREEN}✅ NATS Surveyor (Prometheus Exporter) 正常運行${NC}"
    echo -e "${BLUE}📊 Prometheus Metrics: http://localhost:7777/metrics${NC}"
    
    # 計算 metrics 數量
    metrics_count=$(curl -s "http://localhost:7777/metrics" | grep -c "^# HELP")
    echo -e "${GREEN}📈 可用指標數量: $metrics_count${NC}"
else
    echo -e "${RED}❌ NATS Surveyor 無法存取${NC}"
fi

# 檢查額外的 Prometheus Exporter
if curl -s -f "http://localhost:7778/metrics" > /dev/null; then
    echo -e "${GREEN}✅ NATS Prometheus Exporter 正常運行${NC}"
    echo -e "${BLUE}📊 額外 Prometheus Metrics: http://localhost:7778/metrics${NC}"
else
    echo -e "${RED}❌ NATS Prometheus Exporter 無法存取${NC}"
fi

# 檢查 Prometheus
if curl -s -f "http://localhost:9090/-/healthy" > /dev/null; then
    echo -e "${GREEN}✅ Prometheus 正常運行${NC}"
    echo -e "${BLUE}📊 Prometheus UI: http://localhost:9090${NC}"
else
    echo -e "${RED}❌ Prometheus 無法存取${NC}"
fi

# 檢查 Grafana
if curl -s -f "http://localhost:3000/api/health" > /dev/null; then
    echo -e "${GREEN}✅ Grafana 正常運行${NC}"
    echo -e "${BLUE}📊 Grafana UI: http://localhost:3000 (admin/admin123)${NC}"
else
    echo -e "${RED}❌ Grafana 無法存取${NC}"
fi

# 檢查 NATS Box
if docker compose ps nats-box | grep -q "Up"; then
    echo -e "${GREEN}✅ NATS Box 管理容器正常運行${NC}"
    echo -e "${BLUE}🔧 可使用指令: docker compose exec nats-box nats --help${NC}"
else
    echo -e "${RED}❌ NATS Box 管理容器未運行${NC}"
fi
echo ""

echo "📊 6. Prometheus Metrics 檢查..."
echo -e "${YELLOW}⚠️  NATS 2.10 不支援內建 /metrics 端點${NC}"
echo -e "${BLUE}💡 如需 Prometheus 監控，請使用 NATS Exporter: https://github.com/nats-io/prometheus-nats-exporter${NC}"
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
echo -e "${GREEN}🖥️  NATS 管理介面:${NC}"
echo -e "   Node 1 Monitor: http://localhost:8222"
echo -e "   Node 2 Monitor: http://localhost:8223"
echo -e "   Node 3 Monitor: http://localhost:8224"
echo ""
echo -e "${GREEN}📊 Prometheus Metrics:${NC}"
echo -e "   NATS Surveyor: http://localhost:7777/metrics"
echo -e "   NATS Exporter: http://localhost:7778/metrics"
echo -e "   Prometheus UI: http://localhost:9090"
echo ""
echo -e "${GREEN}📈 視覺化監控:${NC}"
echo -e "   Grafana UI: http://localhost:3000 (admin/admin123)"
echo -e "   - NATS JetStream Overview 儀表板"
echo ""
echo -e "${GREEN}🔧 管理工具:${NC}"
echo -e "   NATS CLI: docker compose exec nats-box nats"
echo -e "   NATS Top: docker compose exec nats-box nats-top"
echo -e "   NATS Bench: docker compose exec nats-box nats-bench"
echo ""

echo -e "${GREEN}🎉 測試完成！${NC}"
echo -e "${BLUE}如需更多資訊，請查看 README.md${NC}" 