#!/bin/bash

# Redis Cluster 部署腳本
# 測試環境 - 3 節點集群，最小資源配置

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
    print_info "創建 Redis Cluster 命名空間..."
    kubectl apply -f namespace.yaml
    print_success "命名空間已創建"
}

# 部署 Redis Cluster
deploy_redis_cluster() {
    print_info "部署 Redis Cluster..."
    
    # 使用 Helm 部署
    helm install redis-cluster bitnami/redis-cluster \
        --namespace redis-cluster \
        --create-namespace \
        --values values.yaml \
        --wait \
        --timeout 15m
    
    print_success "Redis Cluster 部署完成"
}

# 驗證部署
verify_deployment() {
    print_info "驗證部署狀態..."
    
    # 等待 Pod 啟動
    echo "等待 Redis Cluster Pods 啟動..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis-cluster -n redis-cluster --timeout=300s
    
    # 檢查 Pod 狀態
    echo "檢查 Pod 狀態..."
    kubectl get pods -n redis-cluster
    
    # 檢查服務狀態
    echo "檢查服務狀態..."
    kubectl get svc -n redis-cluster
    
    # 檢查 PVC 狀態
    echo "檢查 PVC 狀態..."
    kubectl get pvc -n redis-cluster
    
    # 檢查 StatefulSet 狀態
    echo "檢查 StatefulSet 狀態..."
    kubectl get statefulset -n redis-cluster
    
    print_success "部署驗證完成"
}

# 初始化集群
initialize_cluster() {
    print_info "初始化 Redis Cluster..."
    
    # 等待所有節點就緒
    sleep 30
    
    # 檢查集群狀態
    kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 cluster info || true
    
    print_success "Redis Cluster 初始化完成"
}

# 顯示連接資訊
show_connection_info() {
    print_info "Redis Cluster 連接資訊："
    echo
    
    # 獲取節點 IP
    NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    if [ -z "$NODE_IP" ]; then
        NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
    fi
    
    echo "=== 內部連接 ==="
    echo "節點 1: redis-cluster-0.redis-cluster-headless.redis-cluster.svc.cluster.local:6379"
    echo "節點 2: redis-cluster-1.redis-cluster-headless.redis-cluster.svc.cluster.local:6379"
    echo "節點 3: redis-cluster-2.redis-cluster-headless.redis-cluster.svc.cluster.local:6379"
    echo "密碼: redis123"
    echo
    
    echo "=== 外部連接 (NodePort) ==="
    echo "節點 1: ${NODE_IP}:30379"
    echo "節點 2: ${NODE_IP}:30380"
    echo "節點 3: ${NODE_IP}:30381"
    echo "密碼: redis123"
    echo
    
    echo "=== 集群配置 ==="
    echo "主節點: 3 個"
    echo "副本: 0 個 (最小化配置)"
    echo "持久化: AOF + RDB"
    echo "內存限制: 200MB 每節點"
    echo "存儲: 2Gi 每節點 (Longhorn)"
    echo
    
    echo "=== 資源配置 ==="
    echo "CPU 請求: 50m, 限制: 200m"
    echo "記憶體 請求: 64Mi, 限制: 256Mi"
    echo "存儲: 2Gi 每節點"
    echo
}

# 顯示測試命令
show_test_commands() {
    print_info "測試命令："
    echo
    
    echo "# 測試集群狀態"
    echo "kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 cluster info"
    echo
    
    echo "# 測試集群節點"
    echo "kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 cluster nodes"
    echo
    
    echo "# 測試數據操作"
    echo "kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c set test-key 'Hello Redis Cluster'"
    echo "kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c get test-key"
    echo
    
    echo "# 測試集群分片"
    echo "kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c set '{user1}:name' 'Alice'"
    echo "kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c set '{user1}:age' '25'"
    echo "kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c mget '{user1}:name' '{user1}:age'"
    echo
    
    echo "# 查看日誌"
    echo "kubectl logs -n redis-cluster redis-cluster-0"
    echo "kubectl logs -n redis-cluster redis-cluster-1"
    echo "kubectl logs -n redis-cluster redis-cluster-2"
    echo
    
    echo "# 查看資源使用"
    echo "kubectl top pods -n redis-cluster"
    echo
}

# 創建測試腳本
create_test_script() {
    print_info "創建測試腳本..."
    
    cat > test-cluster.sh << 'EOF'
#!/bin/bash

# Redis Cluster 測試腳本

set -e

echo "=== Redis Cluster 測試 ==="

# 測試集群狀態
echo "1. 測試集群狀態..."
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 cluster info

echo
echo "2. 測試集群節點..."
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 cluster nodes

echo
echo "3. 測試基本數據操作..."
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c set test-key "Hello Redis Cluster"
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c get test-key

echo
echo "4. 測試分片功能..."
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c set '{user1}:name' 'Alice'
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c set '{user1}:age' '25'
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c mget '{user1}:name' '{user1}:age'

echo
echo "5. 測試多個鍵的分布..."
for i in {1..10}; do
    kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c set "key$i" "value$i" > /dev/null
done
echo "已設置 key1-key10"

echo
echo "6. 查看資源使用..."
kubectl top pods -n redis-cluster

echo
echo "Redis Cluster 測試完成！"
EOF
    
    chmod +x test-cluster.sh
    print_success "測試腳本已創建: test-cluster.sh"
}

# 創建卸載腳本
create_uninstall_script() {
    print_info "創建卸載腳本..."
    
    cat > uninstall.sh << 'EOF'
#!/bin/bash

# Redis Cluster 卸載腳本

set -e

echo "=== 卸載 Redis Cluster ==="

# 卸載 Helm release
echo "卸載 Helm release..."
helm uninstall redis-cluster -n redis-cluster

# 刪除 PVC (可選)
read -p "是否刪除 PVC？這會永久刪除數據 (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete pvc --all -n redis-cluster
    echo "PVC 已刪除"
fi

# 刪除命名空間
echo "刪除命名空間..."
kubectl delete namespace redis-cluster

echo "Redis Cluster 卸載完成！"
EOF
    
    chmod +x uninstall.sh
    print_success "卸載腳本已創建: uninstall.sh"
}

# 創建 README
create_readme() {
    print_info "創建 README 文檔..."
    
    cat > README.md << 'EOF'
# Redis Cluster 部署指南

## 概述

本專案提供了一個完整的 Redis Cluster 部署解決方案，適用於 Kubernetes 測試環境。使用 Helm Chart 進行部署，配置 3 主節點無副本的最小化集群架構。

## 功能特性

- ✅ **3 主節點集群**：無副本配置，最小化資源使用
- ✅ **持久化存儲**：使用 Longhorn Storage Class
- ✅ **外部訪問**：NodePort 服務暴露 (30379-30381)
- ✅ **認證保護**：簡單密碼認證
- ✅ **資源優化**：極小化配置，適合測試環境
- ✅ **數據持久化**：AOF + RDB 雙重保障

## 系統需求

- Kubernetes 集群 (v1.19+)
- Helm 3.x
- Longhorn Storage Class
- kubectl 配置正確

## 快速開始

### 1. 部署 Redis Cluster

```bash
chmod +x deploy.sh
./deploy.sh
```

### 2. 測試集群

```bash
chmod +x test-cluster.sh
./test-cluster.sh
```

### 3. 卸載

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## 連接資訊

### 內部連接
- **節點 1**: redis-cluster-0.redis-cluster-headless.redis-cluster.svc.cluster.local:6379
- **節點 2**: redis-cluster-1.redis-cluster-headless.redis-cluster.svc.cluster.local:6379
- **節點 3**: redis-cluster-2.redis-cluster-headless.redis-cluster.svc.cluster.local:6379
- **密碼**: redis123

### 外部連接 (NodePort)
- **節點 1**: <NODE_IP>:30379
- **節點 2**: <NODE_IP>:30380
- **節點 3**: <NODE_IP>:30381
- **密碼**: redis123

## 資源配置

- **CPU**: 50m 請求, 200m 限制 (每節點)
- **記憶體**: 64Mi 請求, 256Mi 限制 (每節點)
- **存儲**: 2Gi (每節點, Longhorn)
- **最大記憶體**: 200MB (每節點)

## 使用範例

### 基本操作
```bash
# 連接到集群
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 -c

# 設置數據
redis-cli> set mykey "Hello Redis Cluster"

# 獲取數據
redis-cli> get mykey
```

### 集群命令
```bash
# 查看集群狀態
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 cluster info

# 查看節點信息
kubectl exec -n redis-cluster redis-cluster-0 -- redis-cli --no-auth-warning -a redis123 cluster nodes
```

## 監控和維護

```bash
# 查看 Pod 狀態
kubectl get pods -n redis-cluster

# 查看資源使用
kubectl top pods -n redis-cluster

# 查看日誌
kubectl logs -n redis-cluster redis-cluster-0
```

## 故障排除

### 常見問題

1. **集群初始化失敗**
   - 檢查所有節點是否正常運行
   - 確認網路連接和端口開放

2. **數據寫入失敗**
   - 檢查認證密碼是否正確
   - 確認集群狀態是否正常

3. **連接超時**
   - 檢查服務和端點配置
   - 確認防火牆設置

## 版本資訊

- **Redis 版本**: 7.x
- **Helm Chart**: Bitnami Redis Cluster
- **架構**: 3 主節點，0 副本
- **持久化**: AOF + RDB
EOF
    
    print_success "README 文檔已創建"
}

# 主函數
main() {
    echo "=========================================="
    echo "   Redis Cluster 部署腳本 (測試環境)"
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
    
    # 部署 Redis Cluster
    deploy_redis_cluster
    
    # 驗證部署
    verify_deployment
    
    # 初始化集群
    initialize_cluster
    
    # 顯示連接資訊
    show_connection_info
    
    # 顯示測試命令
    show_test_commands
    
    # 創建輔助腳本
    create_test_script
    create_uninstall_script
    create_readme
    
    print_success "Redis Cluster 部署完成！"
    echo
    echo "下一步："
    echo "1. 測試集群連接: ./test-cluster.sh"
    echo "2. 配置應用程式連接"
    echo "3. 監控集群狀態和資源使用"
    echo "4. 根據需要調整資源配置"
}

# 執行主函數
main "$@"