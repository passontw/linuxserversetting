#!/bin/bash

# Longhorn 安裝腳本

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

# 檢查 kubectl 連接
check_kubectl() {
    print_info "檢查 kubectl 連接..."
    if ! kubectl cluster-info &> /dev/null; then
        print_error "無法連接到 Kubernetes 集群"
        exit 1
    fi
    print_success "kubectl 連接正常"
}

# 檢查 Helm
check_helm() {
    print_info "檢查 Helm..."
    if ! command -v helm &> /dev/null; then
        print_error "Helm 未安裝，請先安裝 Helm"
        exit 1
    fi
    print_success "Helm 已安裝"
}

# 安裝 Longhorn
install_longhorn() {
    print_info "安裝 Longhorn..."
    
    # 添加 Longhorn Helm Repository
    helm repo add longhorn https://charts.longhorn.io
    helm repo update
    
    # 創建 longhorn-system 命名空間
    kubectl create namespace longhorn-system --dry-run=client -o yaml | kubectl apply -f -
    
    # 安裝 Longhorn
    helm install longhorn longhorn/longhorn \
        --namespace longhorn-system \
        --set longhornManager.replicas=2 \
        --set longhornDriver.replicas=2 \
        --set longhornUI.replicas=1 \
        --wait \
        --timeout 10m
    
    print_success "Longhorn 安裝完成"
}

# 驗證安裝
verify_installation() {
    print_info "驗證 Longhorn 安裝..."
    
    # 等待 Pod 啟動
    echo "等待 Longhorn Pods 啟動..."
    kubectl wait --for=condition=ready pod -l app=longhorn-manager -n longhorn-system --timeout=300s
    
    # 檢查 Pod 狀態
    echo "=== Longhorn Pods 狀態 ==="
    kubectl get pods -n longhorn-system
    
    # 檢查 Storage Class
    echo "=== Storage Classes ==="
    kubectl get storageclass
    
    # 檢查 Longhorn UI
    echo "=== Longhorn UI 服務 ==="
    kubectl get svc -n longhorn-system longhorn-frontend
    
    print_success "Longhorn 安裝驗證完成"
}

# 顯示連接資訊
show_connection_info() {
    print_info "Longhorn 連接資訊："
    echo
    
    # 獲取節點 IP
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo "=== Longhorn UI ==="
    echo "訪問地址: http://${NODE_IP}:30880"
    echo "預設用戶名: admin"
    echo "預設密碼: (空)"
    echo
    
    echo "=== Storage Class ==="
    echo "longhorn: 已創建"
    echo "local-path: 預設 (K3s)"
    echo
    
    echo "=== 下一步 ==="
    echo "1. 訪問 Longhorn UI 檢查狀態"
    echo "2. 運行 NATS 部署腳本"
    echo "3. 配置持久化存儲"
}

# 主函數
main() {
    echo "=========================================="
    echo "    Longhorn 安裝腳本"
    echo "=========================================="
    echo
    
    # 執行檢查
    check_kubectl
    check_helm
    
    # 安裝 Longhorn
    install_longhorn
    
    # 驗證安裝
    verify_installation
    
    # 顯示連接資訊
    show_connection_info
    
    print_success "Longhorn 安裝完成！"
    echo
    echo "現在可以部署 NATS 集群了："
    echo "cd k8s/nats-cluster && ./deploy.sh"
}

# 執行主函數
main "$@" 