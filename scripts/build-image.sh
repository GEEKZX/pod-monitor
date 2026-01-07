#!/bin/bash

# Docker 镜像构建和推送脚本 (Linux/Mac)
# 使用方法: REGISTRY="registry.cn-hangzhou.aliyuncs.com" NAMESPACE="your-namespace" TAG="v1.0.0" ./scripts/build-image.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
REGISTRY="${REGISTRY:-registry.cn-hangzhou.aliyuncs.com}"
NAMESPACE="${NAMESPACE:-}"
TAG="${TAG:-v1.0.0}"
SKIP_PUSH="${SKIP_PUSH:-false}"

# 检查参数
if [ -z "$NAMESPACE" ]; then
    echo -e "${RED}错误: 请指定命名空间${NC}"
    echo "使用方法: REGISTRY=\"registry.cn-hangzhou.aliyuncs.com\" NAMESPACE=\"your-namespace\" TAG=\"v1.0.0\" ./scripts/build-image.sh"
    exit 1
fi

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装或不在 PATH 中${NC}"
    exit 1
fi

# 设置镜像地址
IMAGE_NAME="podmonitor-controller"
IMAGE="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}:${TAG}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PodMonitor Operator 镜像构建脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "镜像仓库: ${REGISTRY}"
echo "命名空间: ${NAMESPACE}"
echo "镜像标签: ${TAG}"
echo "完整地址: ${IMAGE}"
echo ""

# 步骤 1: 构建镜像
echo -e "${YELLOW}[1/3] 构建 Docker 镜像...${NC}"
docker build -t "${IMAGE}" .
if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 镜像构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 镜像构建成功${NC}"
echo ""

# 步骤 2: 登录镜像仓库
if [ "$SKIP_PUSH" != "true" ]; then
    echo -e "${YELLOW}[2/3] 登录镜像仓库...${NC}"
    echo "请输入登录信息（或按 Ctrl+C 跳过，稍后手动登录）"
    docker login "${REGISTRY}" || {
        echo -e "${YELLOW}警告: 登录失败，请手动执行: docker login ${REGISTRY}${NC}"
        read -p "是否继续推送？(y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}跳过推送，请稍后手动执行: docker push ${IMAGE}${NC}"
            exit 0
        fi
    }
    echo -e "${GREEN}✓ 登录成功${NC}"
    echo ""

    # 步骤 3: 推送镜像
    echo -e "${YELLOW}[3/3] 推送镜像到仓库...${NC}"
    docker push "${IMAGE}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 镜像推送失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ 镜像推送成功${NC}"
else
    echo -e "${YELLOW}跳过推送（使用 SKIP_PUSH=true）${NC}"
    echo "手动推送命令: docker push ${IMAGE}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "镜像地址: ${IMAGE}"
echo ""
echo "下一步:"
echo "1. 验证镜像: docker pull ${IMAGE}"
echo "2. 使用 Helm 安装: 参考 INSTALL_FROM_HELM.md"
echo ""

