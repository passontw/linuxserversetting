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
