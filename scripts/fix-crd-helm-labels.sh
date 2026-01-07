#!/bin/bash

# 修复 CRD 的 Helm 标签和注解脚本
# 使用方法: ./scripts/fix-crd-helm-labels.sh

set -e

CRD_NAME="podmonitors.podmonitor.pod-monitor.io"
RELEASE_NAME="podmonitor-operator"
RELEASE_NAMESPACE="podmonitor-system"

echo "检查 CRD 是否存在..."
if ! kubectl get crd ${CRD_NAME} &>/dev/null; then
    echo "CRD ${CRD_NAME} 不存在，无需修复"
    exit 0
fi

echo "给 CRD 添加 Helm 标签..."
kubectl label crd ${CRD_NAME} \
  app.kubernetes.io/managed-by=Helm \
  --overwrite

echo "给 CRD 添加 Helm 注解..."
kubectl annotate crd ${CRD_NAME} \
  meta.helm.sh/release-name=${RELEASE_NAME} \
  meta.helm.sh/release-namespace=${RELEASE_NAMESPACE} \
  --overwrite

echo "验证标签和注解..."
kubectl get crd ${CRD_NAME} -o jsonpath='{.metadata.labels.app\.kubernetes\.io/managed-by}' && echo ""
kubectl get crd ${CRD_NAME} -o jsonpath='{.metadata.annotations.meta\.helm\.sh/release-name}' && echo ""

echo "✓ CRD 标签和注解已修复！"

