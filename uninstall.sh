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
