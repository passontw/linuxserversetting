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