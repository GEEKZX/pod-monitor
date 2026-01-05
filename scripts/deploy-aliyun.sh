#!/bin/bash

# 阿里云 ACK 集群部署脚本
# 使用方法: ./scripts/deploy-aliyun.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量（请根据实际情况修改）
ACR_REGISTRY="${ACR_REGISTRY:-registry.cn-hangzhou.aliyuncs.com}"
ACR_NAMESPACE="${ACR_NAMESPACE:-your-namespace}"
IMAGE_NAME="podmonitor-controller"
IMAGE_TAG="${IMAGE_TAG:-v1.0.0}"
IMAGE="${ACR_REGISTRY}/${ACR_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PodMonitor Operator 部署脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查必要的工具
echo -e "${YELLOW}[1/8] 检查环境...${NC}"
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}错误: kubectl 未安装${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}错误: docker 未安装${NC}" >&2; exit 1; }

# 验证集群连接
echo -e "${YELLOW}[2/8] 验证集群连接...${NC}"
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${RED}错误: 无法连接到 Kubernetes 集群${NC}"
    echo "请确保 kubectl 已正确配置"
    exit 1
fi
echo -e "${GREEN}✓ 集群连接正常${NC}"

# 登录 ACR
echo -e "${YELLOW}[3/8] 登录阿里云容器镜像服务...${NC}"
echo "请输入 ACR 登录信息（或按 Ctrl+C 跳过，稍后手动登录）"
read -p "ACR 用户名 (AccessKey ID): " ACR_USERNAME
read -sp "ACR 密码 (AccessKey Secret): " ACR_PASSWORD
echo ""

if [ -n "$ACR_USERNAME" ] && [ -n "$ACR_PASSWORD" ]; then
    echo "$ACR_PASSWORD" | docker login --username="$ACR_USERNAME" --password-stdin "$ACR_REGISTRY" || {
        echo -e "${YELLOW}警告: 自动登录失败，请手动执行: docker login ${ACR_REGISTRY}${NC}"
    }
else
    echo -e "${YELLOW}跳过自动登录，请手动执行: docker login ${ACR_REGISTRY}${NC}"
fi

# 构建镜像
echo -e "${YELLOW}[4/8] 构建 Docker 镜像...${NC}"
echo "镜像地址: ${IMAGE}"
docker build -t "${IMAGE}" . || {
    echo -e "${RED}错误: 镜像构建失败${NC}"
    exit 1
}
echo -e "${GREEN}✓ 镜像构建成功${NC}"

# 推送镜像
echo -e "${YELLOW}[5/8] 推送镜像到 ACR...${NC}"
docker push "${IMAGE}" || {
    echo -e "${RED}错误: 镜像推送失败${NC}"
    exit 1
}
echo -e "${GREEN}✓ 镜像推送成功${NC}"

# 安装 CRD
echo -e "${YELLOW}[6/8] 安装 CRD...${NC}"
kubectl apply -f config/crd/bases/podmonitor.pod-monitor.io_podmonitors.yaml
echo -e "${GREEN}✓ CRD 安装成功${NC}"

# 部署 RBAC
echo -e "${YELLOW}[7/8] 部署 RBAC...${NC}"
kubectl create namespace podmonitor-system --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f config/rbac/service_account.yaml
kubectl apply -f config/rbac/role.yaml
kubectl apply -f config/rbac/role_binding.yaml
echo -e "${GREEN}✓ RBAC 部署成功${NC}"

# 更新并部署 Operator
echo -e "${YELLOW}[8/8] 部署 Operator...${NC}"

# 创建临时部署文件
TEMP_MANAGER=$(mktemp)
cp config/manager/manager.yaml "$TEMP_MANAGER"

# 更新镜像地址（兼容不同系统）
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|image: podmonitor-controller:latest|image: ${IMAGE}|g" "$TEMP_MANAGER"
else
    # Linux
    sed -i "s|image: podmonitor-controller:latest|image: ${IMAGE}|g" "$TEMP_MANAGER"
fi

# 应用部署文件
kubectl apply -f "$TEMP_MANAGER"
rm "$TEMP_MANAGER"

echo -e "${GREEN}✓ Operator 部署成功${NC}"

# 等待 Pod 就绪
echo ""
echo -e "${YELLOW}等待 Operator Pod 启动...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/podmonitor-controller-manager -n podmonitor-system || {
    echo -e "${YELLOW}警告: Pod 启动超时，请手动检查${NC}"
}

# 显示部署状态
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "部署状态:"
kubectl get pods -n podmonitor-system
echo ""
echo "下一步:"
echo "1. 查看 Operator 日志: kubectl logs -n podmonitor-system deployment/podmonitor-controller-manager -f"
echo "2. 创建监控实例: kubectl apply -f config/samples/podmonitor_v1_podmonitor.yaml"
echo "3. 查看监控状态: kubectl get podmonitor"
echo ""
echo -e "${YELLOW}提示: 如果需要配置邮件通知，请参考 DEPLOY_ALIYUN.md${NC}"

