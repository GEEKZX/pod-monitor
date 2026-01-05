#!/bin/bash

# 快速部署脚本（使用本地构建的镜像，适用于开发测试）
# 使用方法: ./scripts/quick-deploy.sh

set -e

echo "快速部署 PodMonitor Operator..."

# 安装 CRD
echo "[1/4] 安装 CRD..."
kubectl apply -f config/crd/bases/podmonitor.pod-monitor.io_podmonitors.yaml

# 部署 RBAC
echo "[2/4] 部署 RBAC..."
kubectl create namespace podmonitor-system --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f config/rbac/

# 部署 Operator（使用默认镜像）
echo "[3/4] 部署 Operator..."
kubectl apply -f config/manager/manager.yaml

# 等待就绪
echo "[4/4] 等待 Operator 启动..."
kubectl wait --for=condition=available --timeout=300s deployment/podmonitor-controller-manager -n podmonitor-system || true

echo ""
echo "部署完成！"
echo "查看状态: kubectl get pods -n podmonitor-system"
echo "查看日志: kubectl logs -n podmonitor-system deployment/podmonitor-controller-manager -f"

