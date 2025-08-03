#!/bin/bash

# NATS 集群卸載腳本

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

# 確認卸載
confirm_uninstall() {
    print_warning "此操作將完全移除 NATS 集群和所有相關資源"
    print_warning "包括："
    echo "  - NATS Pods"
    echo "  - NATS Services"
    echo "  - NATS PVCs (持久化存儲)"
    echo "  - NATS ConfigMaps"
    echo "  - NATS Secrets"
    echo "  - NATS 命名空間"
    echo
    
    read -p "確定要卸載 NATS 集群嗎？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "取消卸載操作"
        exit 0
    fi
}

# 卸載 NATS Helm Release
uninstall_nats() {
    print_info "卸載 NATS Helm Release..."
    
    if helm list -n nats | grep -q nats; then
        helm uninstall nats -n nats
        print_success "NATS Helm Release 已卸載"
    else
        print_warning "NATS Helm Release 不存在"
    fi
}

# 刪除 PVC
delete_pvc() {
    print_info "刪除 PVC..."
    
    # 獲取所有 PVC
    PVCs=$(kubectl get pvc -n nats -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [ -n "$PVCs" ]; then
        for pvc in $PVCs; do
            print_info "刪除 PVC: $pvc"
            kubectl delete pvc "$pvc" -n nats
        done
        print_success "所有 PVC 已刪除"
    else
        print_warning "沒有找到 PVC"
    fi
}

# 刪除命名空間
delete_namespace() {
    print_info "刪除 NATS 命名空間..."
    
    if kubectl get namespace nats &> /dev/null; then
        kubectl delete namespace nats
        print_success "NATS 命名空間已刪除"
    else
        print_warning "NATS 命名空間不存在"
    fi
}

# 清理殘留資源
cleanup_resources() {
    print_info "清理殘留資源..."
    
    # 清理可能殘留的 ConfigMaps
    kubectl delete configmap -l app.kubernetes.io/name=nats --all-namespaces 2>/dev/null || true
    
    # 清理可能殘留的 Secrets
    kubectl delete secret -l app.kubernetes.io/name=nats --all-namespaces 2>/dev/null || true
    
    # 清理可能殘留的 ServiceAccounts
    kubectl delete serviceaccount -l app.kubernetes.io/name=nats --all-namespaces 2>/dev/null || true
    
    print_success "殘留資源清理完成"
}

# 驗證清理結果
verify_cleanup() {
    print_info "驗證清理結果..."
    
    echo "檢查是否還有 NATS 相關資源："
    
    # 檢查 Pods
    if kubectl get pods -n nats 2>/dev/null | grep -q nats; then
        print_warning "發現殘留的 NATS Pods"
    else
        print_success "沒有殘留的 NATS Pods"
    fi
    
    # 檢查 Services
    if kubectl get svc -n nats 2>/dev/null | grep -q nats; then
        print_warning "發現殘留的 NATS Services"
    else
        print_success "沒有殘留的 NATS Services"
    fi
    
    # 檢查 PVCs
    if kubectl get pvc -n nats 2>/dev/null | grep -q nats; then
        print_warning "發現殘留的 NATS PVCs"
    else
        print_success "沒有殘留的 NATS PVCs"
    fi
    
    # 檢查命名空間
    if kubectl get namespace nats 2>/dev/null; then
        print_warning "NATS 命名空間仍然存在"
    else
        print_success "NATS 命名空間已刪除"
    fi
}

# 顯示清理完成訊息
show_completion() {
    print_success "NATS 集群卸載完成！"
    echo
    echo "注意事項："
    echo "1. 所有 NATS 數據已被刪除"
    echo "2. 持久化存儲已被清理"
    echo "3. 如需重新部署，請運行 deploy.sh"
    echo
}

# 主函數
main() {
    echo "=========================================="
    echo "    NATS 集群卸載腳本"
    echo "=========================================="
    echo
    
    # 確認卸載
    confirm_uninstall
    
    # 執行卸載步驟
    uninstall_nats
    delete_pvc
    delete_namespace
    cleanup_resources
    
    # 驗證清理結果
    verify_cleanup
    
    # 顯示完成訊息
    show_completion
}

# 執行主函數
main "$@" 