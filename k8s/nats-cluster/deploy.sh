#!/bin/bash

# NATS 集群部署腳本
# 測試環境 - 使用 Helm Chart 部署

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

# 檢查 kubectl 是否可用
check_kubectl() {
    print_info "檢查 kubectl 連接..."
    if ! kubectl cluster-info &> /dev/null; then
        print_error "無法連接到 Kubernetes 集群"
        exit 1
    fi
    print_success "kubectl 連接正常"
}

# 檢查 Helm 是否可用
check_helm() {
    print_info "檢查 Helm 是否安裝..."
    if ! command -v helm &> /dev/null; then
        print_error "Helm 未安裝，請先安裝 Helm"
        exit 1
    fi
    print_success "Helm 已安裝"
}

# 檢查 Longhorn Storage Class
check_longhorn() {
    print_info "檢查 Longhorn Storage Class..."
    if ! kubectl get storageclass longhorn &> /dev/null; then
        print_warning "Longhorn Storage Class 不存在"
        print_info "請確保已安裝 Longhorn"
        read -p "是否繼續部署？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Longhorn Storage Class 存在"
    fi
}

# 添加 NATS Helm Repository
add_helm_repo() {
    print_info "添加 NATS Helm Repository..."
    helm repo add nats https://nats-io.github.io/k8s/helm/charts/
    helm repo update
    print_success "NATS Helm Repository 已添加"
}

# 創建命名空間
create_namespace() {
    print_info "創建 NATS 命名空間..."
    kubectl apply -f namespace.yaml
    print_success "命名空間已創建"
}

# 部署 NATS 集群
deploy_nats() {
    print_info "部署 NATS 集群..."
    
    # 使用 Helm 部署
    helm install nats nats/nats \
        --namespace nats \
        --create-namespace \
        --values values.yaml \
        --wait \
        --timeout 10m
    
    print_success "NATS 集群部署完成"
}

# 驗證部署
verify_deployment() {
    print_info "驗證部署狀態..."
    
    # 檢查 Pod 狀態
    echo "檢查 Pod 狀態..."
    kubectl get pods -n nats
    
    # 檢查服務狀態
    echo "檢查服務狀態..."
    kubectl get svc -n nats
    
    # 檢查 PVC 狀態
    echo "檢查 PVC 狀態..."
    kubectl get pvc -n nats
    
    # 檢查 Storage Class
    echo "檢查 Storage Class..."
    kubectl get storageclass
    
    print_success "部署驗證完成"
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
    
    echo "=== 內部連接 ==="
    echo "NATS 服務: nats.nats.svc.cluster.local:4222"
    echo "監控服務: nats.nats.svc.cluster.local:8222"
    echo
    
    echo "=== 外部連接 (NodePort) ==="
    echo "NATS 服務: ${NODE_IP}:30222"
    echo "監控服務: ${NODE_IP}:30822"
    echo
    
    echo "=== 用戶認證 ==="
    echo "管理員用戶:"
    echo "  用戶名: admin"
    echo "  密碼: admin123"
    echo "  權限: 全部權限"
    echo
    echo "一般用戶:"
    echo "  用戶名: user1"
    echo "  密碼: user123"
    echo "  權限: app.*, service.*"
    echo
    echo "唯讀用戶:"
    echo "  用戶名: readonly"
    echo "  密碼: read123"
    echo "  權限: 只能訂閱"
    echo
    
    echo "=== JetStream 配置 ==="
    echo "記憶體存儲: 1Gi (可動態擴展)"
    echo "檔案存儲: 10Gi (Longhorn)"
    echo "存儲目錄: /data/jetstream"
    echo
}

# 顯示測試命令
show_test_commands() {
    print_info "測試命令："
    echo
    
    echo "# 測試 NATS 連接"
    echo "kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- nats-sub -s nats://admin:admin123@nats.nats.svc.cluster.local:4222 'test.>'"
    echo
    
    echo "# 測試 JetStream"
    echo "kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- nats stream add test-stream --subjects 'test.*' --storage file --replicas 3"
    echo
    
    echo "# 查看集群狀態"
    echo "kubectl logs -n nats deployment/nats"
    echo
    
    echo "# 查看 JetStream 資訊"
    echo "kubectl run nats-test --rm -it --image natsio/nats-box --restart=Never -- nats stream list"
    echo
}

# 主函數
main() {
    echo "=========================================="
    echo "    NATS 集群部署腳本 (測試環境)"
    echo "=========================================="
    echo
    
    # 執行檢查
    check_kubectl
    check_helm
    check_longhorn
    
    # 添加 Helm Repository
    add_helm_repo
    
    # 創建命名空間
    create_namespace
    
    # 部署 NATS
    deploy_nats
    
    # 驗證部署
    verify_deployment
    
    # 顯示連接資訊
    show_connection_info
    
    # 顯示測試命令
    show_test_commands
    
    print_success "NATS 集群部署完成！"
    echo
    echo "下一步："
    echo "1. 測試連接是否正常"
    echo "2. 配置應用程式連接"
    echo "3. 監控集群狀態"
    echo "4. 根據需要調整資源配置"
}

# 執行主函數
main "$@" 