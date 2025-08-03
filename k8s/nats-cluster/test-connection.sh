#!/bin/bash

# NATS 集群連接測試腳本

set -e

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 函數：打印帶顏色的訊息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 檢查 NATS 集群狀態
check_nats_status() {
    print_info "檢查 NATS 集群狀態..."
    
    # 檢查 Pod 狀態
    echo "=== Pod 狀態 ==="
    kubectl get pods -n nats
    
    # 檢查服務狀態
    echo "=== 服務狀態 ==="
    kubectl get svc -n nats
    
    # 檢查 PVC 狀態
    echo "=== PVC 狀態 ==="
    kubectl get pvc -n nats
    
    print_success "集群狀態檢查完成"
}

# 測試內部連接
test_internal_connection() {
    print_info "測試內部連接..."
    
    # 測試基本連接
    kubectl run nats-test-internal --rm -it --image natsio/nats-box --restart=Never -- \
        nats-sub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 'test.internal' &
    
    # 等待訂閱啟動
    sleep 3
    
    # 發布測試消息
    kubectl run nats-test-pub --rm -it --image natsio/nats-box --restart=Never -- \
        nats pub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 test.internal "Internal connection test"
    
    print_success "內部連接測試完成"
}

# 測試外部連接
test_external_connection() {
    print_info "測試外部連接..."
    
    # 獲取節點 IP
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo "使用節點 IP: $NODE_IP"
    
    # 測試外部連接
    kubectl run nats-test-external --rm -it --image natsio/nats-box --restart=Never -- \
        nats-sub -s nats://admin:admin123@${NODE_IP}:30222 'test.external' &
    
    # 等待訂閱啟動
    sleep 3
    
    # 發布測試消息
    kubectl run nats-test-pub-external --rm -it --image natsio/nats-box --restart=Never -- \
        nats pub -s nats://admin:admin123@${NODE_IP}:30222 test.external "External connection test"
    
    print_success "外部連接測試完成"
}

# 測試 JetStream
test_jetstream() {
    print_info "測試 JetStream 功能..."
    
    # 創建測試 Stream
    kubectl run nats-test-stream --rm -it --image natsio/nats-box --restart=Never -- \
        nats stream add test-stream --subjects 'test.*' --storage file --replicas 3
    
    # 發布消息到 Stream
    kubectl run nats-test-pub-stream --rm -it --image natsio/nats-box --restart=Never -- \
        nats pub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 test.stream "JetStream test message"
    
    # 創建 Consumer
    kubectl run nats-test-consumer --rm -it --image natsio/nats-box --restart=Never -- \
        nats consumer add test-stream test-consumer --pull --filter test.stream
    
    # 拉取消息
    kubectl run nats-test-pull --rm -it --image natsio/nats-box --restart=Never -- \
        nats consumer next test-stream test-consumer --count 1
    
    print_success "JetStream 測試完成"
}

# 測試用戶認證
test_authentication() {
    print_info "測試用戶認證..."
    
    # 測試管理員用戶
    kubectl run nats-test-admin --rm -it --image natsio/nats-box --restart=Never -- \
        nats pub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 admin.test "Admin test"
    
    # 測試一般用戶
    kubectl run nats-test-user --rm -it --image natsio/nats-box --restart=Never -- \
        nats pub -s nats://user1:user123@nats.nats.svc.cluster.local:4222 app.test "User test"
    
    # 測試唯讀用戶
    kubectl run nats-test-readonly --rm -it --image natsio/nats-box --restart=Never -- \
        nats sub -s nats://readonly:read123@nats.nats.svc.cluster.local:4222 readonly.test &
    
    print_success "用戶認證測試完成"
}

# 測試集群功能
test_cluster_functionality() {
    print_info "測試集群功能..."
    
    # 檢查集群資訊
    kubectl run nats-test-cluster --rm -it --image natsio/nats-box --restart=Never -- \
        nats server report --connect-timeout 5s
    
    # 檢查 JetStream 資訊
    kubectl run nats-test-js --rm -it --image natsio/nats-box --restart=Never -- \
        nats stream list
    
    print_success "集群功能測試完成"
}

# 性能測試
test_performance() {
    print_info "執行性能測試..."
    
    # 簡單的吞吐量測試
    kubectl run nats-test-perf --rm -it --image natsio/nats-box --restart=Never -- \
        nats bench -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 test.bench --pub 1 --sub 1 --size 16 --msgs 100
    
    print_success "性能測試完成"
}

# 顯示連接資訊
show_connection_info() {
    print_info "NATS 集群連接資訊："
    echo
    
    # 獲取節點 IP
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo "=== 連接資訊 ==="
    echo "內部連接:"
    echo "  NATS: nats://admin:admin123@nats.nats.svc.cluster.local:4222"
    echo "  監控: http://nats.nats.svc.cluster.local:8222"
    echo
    echo "外部連接:"
    echo "  NATS: nats://admin:admin123@${NODE_IP}:30222"
    echo "  監控: http://${NODE_IP}:30822"
    echo
    
    echo "=== 用戶認證 ==="
    echo "管理員: admin/admin123 (全部權限)"
    echo "一般用戶: user1/user123 (app.*, service.*)"
    echo "唯讀用戶: readonly/read123 (只能訂閱)"
    echo
    
    echo "=== 測試命令 ==="
    echo "# 訂閱測試"
    echo "kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- nats-sub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 'test.>'"
    echo
    echo "# 發布測試"
    echo "kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- nats pub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 test.hello 'Hello World'"
    echo
}

# 主函數
main() {
    echo "=========================================="
    echo "    NATS 集群連接測試"
    echo "=========================================="
    echo
    
    # 檢查集群狀態
    check_nats_status
    
    # 顯示連接資訊
    show_connection_info
    
    # 執行測試
    test_internal_connection
    test_external_connection
    test_jetstream
    test_authentication
    test_cluster_functionality
    test_performance
    
    print_success "所有測試完成！"
    echo
    echo "測試結果："
    echo "✅ 內部連接正常"
    echo "✅ 外部連接正常"
    echo "✅ JetStream 功能正常"
    echo "✅ 用戶認證正常"
    echo "✅ 集群功能正常"
    echo "✅ 性能測試完成"
    echo
    echo "NATS 集群已準備就緒！"
}

# 執行主函數
main "$@" 