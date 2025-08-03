#!/bin/bash

# PostgreSQL 部署腳本
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

# 添加 Bitnami Helm Repository
add_helm_repo() {
    print_info "添加 Bitnami Helm Repository..."
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm repo update
    print_success "Bitnami Helm Repository 已添加"
}

# 創建命名空間
create_namespace() {
    print_info "創建 PostgreSQL 命名空間..."
    kubectl apply -f namespace.yaml
    print_success "命名空間已創建"
}

# 部署 PostgreSQL
deploy_postgresql() {
    print_info "部署 PostgreSQL..."
    
    # 使用 Helm 部署
    helm install postgresql bitnami/postgresql \
        --namespace postgresql \
        --create-namespace \
        --values values.yaml \
        --wait \
        --timeout 10m
    
    print_success "PostgreSQL 部署完成"
}

# 驗證部署
verify_deployment() {
    print_info "驗證部署狀態..."
    
    # 檢查 Pod 狀態
    echo "檢查 Pod 狀態..."
    kubectl get pods -n postgresql
    
    # 檢查服務狀態
    echo "檢查服務狀態..."
    kubectl get svc -n postgresql
    
    # 檢查 PVC 狀態
    echo "檢查 PVC 狀態..."
    kubectl get pvc -n postgresql
    
    # 檢查 Secret 狀態
    echo "檢查 Secret 狀態..."
    kubectl get secrets -n postgresql
    
    print_success "部署驗證完成"
}

# 顯示連接資訊
show_connection_info() {
    print_info "PostgreSQL 連接資訊："
    echo
    
    # 獲取節點 IP
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo "=== 內部連接 ==="
    echo "主機: postgresql.postgresql.svc.cluster.local"
    echo "端口: 5432"
    echo "數據庫: testdb"
    echo "用戶名: postgres"
    echo "密碼: postgres123"
    echo
    
    echo "=== 外部連接 (NodePort) ==="
    echo "主機: ${NODE_IP}"
    echo "端口: 30432"
    echo "數據庫: testdb"
    echo "用戶名: postgres"
    echo "密碼: postgres123"
    echo
    
    echo "=== 連接字符串 ==="
    echo "內部: postgresql://postgres:postgres123@postgresql.postgresql.svc.cluster.local:5432/testdb"
    echo "外部: postgresql://postgres:postgres123@${NODE_IP}:30432/testdb"
    echo
    
    echo "=== 資源配置 ==="
    echo "CPU 請求: 100m, 限制: 500m"
    echo "記憶體 請求: 128Mi, 限制: 1Gi"
    echo "存儲: 8Gi (Longhorn)"
    echo
}

# 顯示測試命令
show_test_commands() {
    print_info "測試命令："
    echo
    
    echo "# 連接到 PostgreSQL (Pod 內)"
    echo "kubectl run postgresql-client --rm -it --image postgres:15 --restart=Never -- psql -h postgresql.postgresql.svc.cluster.local -U postgres -d testdb"
    echo
    
    echo "# 檢查數據庫狀態"
    echo "kubectl exec -n postgresql deployment/postgresql -- psql -U postgres -d testdb -c 'SELECT version();'"
    echo
    
    echo "# 查看日誌"
    echo "kubectl logs -n postgresql deployment/postgresql"
    echo
    
    echo "# 查看資源使用"
    echo "kubectl top pods -n postgresql"
    echo
    
    echo "# 獲取密碼"
    echo "kubectl get secret --namespace postgresql postgresql -o jsonpath='{.data.postgres-password}' | base64 -d"
    echo
}

# 創建測試腳本
create_test_script() {
    print_info "創建測試腳本..."
    
    cat > test-connection.sh << 'EOF'
#!/bin/bash

# PostgreSQL 連接測試腳本

set -e

echo "=== PostgreSQL 連接測試 ==="

# 測試內部連接
echo "測試內部連接..."
kubectl run postgresql-test --rm -it --image postgres:15 --restart=Never -- \
  psql -h postgresql.postgresql.svc.cluster.local -U postgres -d testdb -c "SELECT 'PostgreSQL is running!' as status, version();"

echo "測試完成！"
EOF
    
    chmod +x test-connection.sh
    print_success "測試腳本已創建: test-connection.sh"
}

# 創建卸載腳本
create_uninstall_script() {
    print_info "創建卸載腳本..."
    
    cat > uninstall.sh << 'EOF'
#!/bin/bash

# PostgreSQL 卸載腳本

set -e

echo "=== 卸載 PostgreSQL ==="

# 卸載 Helm release
echo "卸載 Helm release..."
helm uninstall postgresql -n postgresql

# 刪除 PVC (可選)
read -p "是否刪除 PVC？這會永久刪除數據 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete pvc --all -n postgresql
    echo "PVC 已刪除"
fi

# 刪除命名空間
echo "刪除命名空間..."
kubectl delete namespace postgresql

echo "PostgreSQL 卸載完成！"
EOF
    
    chmod +x uninstall.sh
    print_success "卸載腳本已創建: uninstall.sh"
}

# 創建 README
create_readme() {
    print_info "創建 README 文檔..."
    
    cat > README.md << 'EOF'
# PostgreSQL 部署指南

## 概述

本專案提供了一個完整的 PostgreSQL 部署解決方案，適用於 Kubernetes 測試環境。使用 Helm Chart 進行部署，支援持久化存儲、NodePort 外部訪問等功能。

## 功能特性

- ✅ **單節點部署**：適合測試環境
- ✅ **持久化存儲**：使用 Longhorn Storage Class
- ✅ **外部訪問**：NodePort 服務暴露
- ✅ **資源優化**：最小配置，支援自動擴展
- ✅ **安全配置**：用戶認證和權限管理

## 快速開始

### 1. 部署 PostgreSQL

```bash
chmod +x deploy.sh
./deploy.sh
```

### 2. 測試連接

```bash
chmod +x test-connection.sh
./test-connection.sh
```

### 3. 卸載

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## 連接資訊

- **內部**: postgresql.postgresql.svc.cluster.local:5432
- **外部**: <NODE_IP>:30432
- **用戶名**: postgres
- **密碼**: postgres123
- **數據庫**: testdb

## 資源配置

- **CPU**: 100m 請求, 500m 限制
- **記憶體**: 128Mi 請求, 1Gi 限制  
- **存儲**: 8Gi (Longhorn)
EOF
    
    print_success "README 文檔已創建"
}

# 主函數
main() {
    echo "=========================================="
    echo "    PostgreSQL 部署腳本 (測試環境)"
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
    
    # 部署 PostgreSQL
    deploy_postgresql
    
    # 驗證部署
    verify_deployment
    
    # 顯示連接資訊
    show_connection_info
    
    # 顯示測試命令
    show_test_commands
    
    # 創建輔助腳本
    create_test_script
    create_uninstall_script
    create_readme
    
    print_success "PostgreSQL 部署完成！"
    echo
    echo "下一步："
    echo "1. 測試連接是否正常: ./test-connection.sh"
    echo "2. 配置應用程式連接"
    echo "3. 監控資源使用情況"
    echo "4. 根據需要調整資源配置"
}

# 執行主函數
main "$@"