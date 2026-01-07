#!/bin/bash

# 创建示例僵尸 Pod 脚本
# 使用方法: ./scripts/create-zombie-pod.sh [namespace] [pod-name]

set -e

NAMESPACE=${1:-default}
POD_NAME=${2:-zombie-pod-test-$(date +%s)}

echo "创建测试用的僵尸 Pod..."
echo "命名空间: ${NAMESPACE}"
echo "Pod 名称: ${POD_NAME}"
echo ""

# 创建一个会长时间运行的 Pod
kubectl run ${POD_NAME} \
  --image=busybox:latest \
  --namespace=${NAMESPACE} \
  --restart=Never \
  -- /bin/sh -c "echo '这是一个测试僵尸 Pod，会持续运行'; while true; do sleep 3600; done"

echo "✓ Pod 已创建: ${POD_NAME}"
echo ""
echo "等待 Pod 启动..."
kubectl wait --for=condition=Ready pod/${POD_NAME} -n ${NAMESPACE} --timeout=60s || true

echo ""
echo "Pod 信息:"
kubectl get pod ${POD_NAME} -n ${NAMESPACE} -o wide

echo ""
echo "提示:"
echo "1. 如果 PodMonitor 的 maxRunDurationSeconds 设置为 3600 秒（1小时），这个 Pod 运行超过 1 小时后会被检测为僵尸 Pod"
echo "2. 如果想更快看到效果，可以调整 PodMonitor 的 maxRunDurationSeconds 为更短的时间（如 300 秒）"
echo "3. 查看 Pod 状态: kubectl get pod ${POD_NAME} -n ${NAMESPACE}"
echo "4. 删除 Pod: kubectl delete pod ${POD_NAME} -n ${NAMESPACE}"

