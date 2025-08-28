#!/bin/bash

# Backend Service 部署腳本
# 測試環境 - 使用 nginx 作為佔位符

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

# 檢查依賴服務
check_dependencies() {
    print_info "檢查依賴服務狀態..."
    
    # 檢查 PostgreSQL
    if kubectl get pods -n postgresql -l app.kubernetes.io/name=postgresql | grep -q Running; then
        print_success "PostgreSQL 服務運行正常"
    else
        print_warning "PostgreSQL 服務未運行，請先部署 PostgreSQL"
    fi
    
    # 檢查 Redis Cluster
    if kubectl get pods -n redis-cluster -l app.kubernetes.io/name=redis-cluster | grep -q Running; then
        print_success "Redis Cluster 服務運行正常"
    else
        print_warning "Redis Cluster 服務未運行，請先部署 Redis Cluster"
    fi
}

# 創建命名空間
create_namespace() {
    print_info "創建 Backend Service 命名空間..."
    
    # 獲取腳本所在目錄
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    kubectl apply -f "${SCRIPT_DIR}/namespace.yaml"
    print_success "命名空間已創建"
}

# 部署配置和秘密
deploy_configs() {
    print_info "部署配置和秘密..."
    
    # 獲取腳本所在目錄
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    kubectl apply -f "${SCRIPT_DIR}/configmap.yaml"
    kubectl apply -f "${SCRIPT_DIR}/secret.yaml"
    print_success "配置和秘密已部署"
}

# 部署 Backend Service
deploy_backend_service() {
    print_info "部署 Backend Service..."
    
    # 獲取腳本所在目錄
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    kubectl apply -f "${SCRIPT_DIR}/deployment.yaml"
    kubectl apply -f "${SCRIPT_DIR}/service.yaml"
    print_success "Backend Service 已部署"
}

# 等待部署完成
wait_for_deployment() {
    print_info "等待部署完成..."
    
    # 等待 Deployment 就緒
    kubectl wait --for=condition=available deployment/backend-service -n backend-service --timeout=300s
    
    print_success "部署已完成"
}

# 驗證部署
verify_deployment() {
    print_info "驗證部署狀態..."
    
    # 檢查 Pod 狀態
    echo "檢查 Pod 狀態..."
    kubectl get pods -n backend-service
    
    # 檢查服務狀態
    echo "檢查服務狀態..."
    kubectl get svc -n backend-service
    
    # 檢查 ConfigMap 和 Secret
    echo "檢查配置狀態..."
    kubectl get configmap -n backend-service
    kubectl get secret -n backend-service
    
    print_success "部署驗證完成"
}

# 顯示連接資訊
show_connection_info() {
    print_info "Backend Service 連接資訊："
    echo
    
    # 獲取節點 IP
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo "=== 內部連接 ==="
    echo "服務名稱: backend-service.backend-service.svc.cluster.local"
    echo "端口: 8080"
    echo "健康檢查: http://backend-service.backend-service.svc.cluster.local:8080/health"
    echo
    
    echo "=== 外部連接 (NodePort) ==="
    echo "主機: ${NODE_IP}"
    echo "端口: 30080"
    echo "健康檢查: http://${NODE_IP}:30080/health"
    echo
    
    echo "=== 服務配置 ==="
    echo "副本數: 2"
    echo "CPU 請求/限制: 100m/500m"
    echo "記憶體 請求/限制: 128Mi/512Mi"
    echo "鏡像: nginx:1.21-alpine (臨時)"
    echo
    
    echo "=== 連接的服務 ==="
    echo "PostgreSQL: postgresql.postgresql.svc.cluster.local:5432"
    echo "Redis Cluster: redis-cluster.redis-cluster.svc.cluster.local:6379"
    echo
}

# 顯示測試命令
show_test_commands() {
    print_info "測試命令："
    echo
    
    echo "# 檢查服務狀態"
    echo "kubectl get pods -n backend-service"
    echo "kubectl get svc -n backend-service"
    echo
    
    echo "# 測試健康檢查"
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    echo "curl http://${NODE_IP}:30080/"
    echo
    
    echo "# 查看日誌"
    echo "kubectl logs -n backend-service deployment/backend-service"
    echo
    
    echo "# 進入容器"
    echo "kubectl exec -n backend-service -it deployment/backend-service -- /bin/sh"
    echo
    
    echo "# 查看環境變數"
    echo "kubectl exec -n backend-service deployment/backend-service -- env | grep -E '(POSTGRES|REDIS|APP)'"
    echo
    
    echo "# 查看資源使用"
    echo "kubectl top pods -n backend-service"
    echo
}

# 創建測試腳本
create_test_script() {
    print_info "創建測試腳本..."
    
    cat > test-service.sh << 'EOF'
#!/bin/bash

# Backend Service 測試腳本

set -e

echo "=== Backend Service 測試 ==="

# 獲取節點 IP
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')

echo "1. 檢查 Pod 狀態..."
kubectl get pods -n backend-service

echo
echo "2. 檢查服務狀態..."
kubectl get svc -n backend-service

echo
echo "3. 測試外部連接..."
echo "測試 URL: http://${NODE_IP}:30080"
curl -f -s -o /dev/null http://${NODE_IP}:30080 && echo "✅ 外部連接成功" || echo "❌ 外部連接失敗"

echo
echo "4. 檢查環境變數配置..."
kubectl exec -n backend-service deployment/backend-service -- env | grep -E '(POSTGRES|REDIS|APP)' | head -10

echo
echo "5. 查看資源使用..."
kubectl top pods -n backend-service

echo
echo "Backend Service 測試完成！"
EOF
    
    chmod +x test-service.sh
    print_success "測試腳本已創建: test-service.sh"
}

# 創建卸載腳本
create_uninstall_script() {
    print_info "創建卸載腳本..."
    
    cat > uninstall.sh << 'EOF'
#!/bin/bash

# Backend Service 卸載腳本

set -e

echo "=== 卸載 Backend Service ==="

# 刪除部署
echo "刪除部署資源..."
kubectl delete deployment backend-service -n backend-service --ignore-not-found=true
kubectl delete service backend-service backend-service-headless -n backend-service --ignore-not-found=true
kubectl delete configmap backend-service-config -n backend-service --ignore-not-found=true
kubectl delete secret backend-service-secret -n backend-service --ignore-not-found=true

# 刪除命名空間
echo "刪除命名空間..."
kubectl delete namespace backend-service --ignore-not-found=true

echo "Backend Service 卸載完成！"
EOF
    
    chmod +x uninstall.sh
    print_success "卸載腳本已創建: uninstall.sh"
}

# 主函數
main() {
    echo "=========================================="
    echo "   Backend Service 部署腳本 (測試環境)"
    echo "=========================================="
    echo
    
    # 執行檢查
    check_kubectl
    check_dependencies
    
    # 創建命名空間
    create_namespace
    
    # 部署配置
    deploy_configs
    
    # 部署服務
    deploy_backend_service
    
    # 等待部署完成
    wait_for_deployment
    
    # 驗證部署
    verify_deployment
    
    # 顯示連接資訊
    show_connection_info
    
    # 顯示測試命令
    show_test_commands
    
    # 創建輔助腳本
    create_test_script
    create_uninstall_script
    
    print_success "Backend Service 部署完成！"
    echo
    echo "注意事項："
    echo "1. 目前使用 nginx 作為佔位符鏡像"
    echo "2. 需要替換為實際的 backend-service 鏡像"
    echo "3. 環境變數已配置好 PostgreSQL 和 Redis 連接"
    echo "4. 測試服務: ./test-service.sh"
    echo "5. 外部訪問: http://${NODE_IP:-<NODE_IP>}:30080"
}

# 執行主函數
main "$@"