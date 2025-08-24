#!/bin/bash

# PostgreSQL 連接測試腳本

set -e

echo "=== PostgreSQL 連接測試 ==="

# 測試內部連接
echo "測試內部連接..."
kubectl run postgresql-client --image postgres:15 --restart=Never --env="PGPASSWORD=postgres123" -- \
  psql -h postgresql.postgresql.svc.cluster.local -U postgres -d postgres -c "SELECT 'PostgreSQL is running!' as status, version();"

# 等待 pod 完成並取得日誌
sleep 5
kubectl logs postgresql-client

# 清理 pod
kubectl delete pod postgresql-client --ignore-not-found=true

echo "測試完成！"