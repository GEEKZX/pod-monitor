#!/bin/bash

# Docker Hub 镜像发布脚本 (Linux/Mac)
# 使用方法: ./scripts/publish-dockerhub.sh <dockerhub-username> [tag] [--latest]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误: 请指定 Docker Hub 用户名${NC}"
    echo "使用方法: $0 <dockerhub-username> [tag] [--latest]"
    echo "示例: $0 myusername v1.0.0 --latest"
    exit 1
fi

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装或不在 PATH 中${NC}"
    exit 1
fi

# 设置变量
USERNAME=$1
TAG=${2:-v1.0.0}
PUSH_LATEST=false

if [ "$3" == "--latest" ]; then
    PUSH_LATEST=true
fi

IMAGE_NAME="podmonitor-controller"
IMAGE="${USERNAME}/${IMAGE_NAME}:${TAG}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}发布镜像到 Docker Hub${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Docker Hub 用户名: ${USERNAME}"
echo "镜像标签: ${TAG}"
echo "完整地址: ${IMAGE}"
if [ "$PUSH_LATEST" == "true" ]; then
    echo "同时推送 latest 标签: 是"
fi
echo ""

# 步骤 1: 构建镜像
echo -e "${YELLOW}[1/4] 构建 Docker 镜像...${NC}"
docker build -t "${IMAGE}" .
if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 镜像构建失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 镜像构建成功${NC}"
echo ""

# 步骤 2: 标记 latest 标签（如果需要）
if [ "$PUSH_LATEST" == "true" ]; then
    echo -e "${YELLOW}[2/4] 标记 latest 标签...${NC}"
    LATEST_IMAGE="${USERNAME}/${IMAGE_NAME}:latest"
    docker tag "${IMAGE}" "${LATEST_IMAGE}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 标记 latest 失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ latest 标签已创建${NC}"
    echo ""
else
    echo -e "${YELLOW}[2/4] 跳过 latest 标签（使用 --latest 参数可同时推送 latest）${NC}"
    echo ""
fi

# 步骤 3: 登录 Docker Hub
echo -e "${YELLOW}[3/4] 登录 Docker Hub...${NC}"
echo "请输入 Docker Hub 登录信息（或按 Ctrl+C 取消）"
docker login || {
    echo -e "${RED}错误: Docker Hub 登录失败${NC}"
    echo "请手动执行: docker login"
    exit 1
}
echo -e "${GREEN}✓ 登录成功${NC}"
echo ""

# 步骤 4: 推送镜像
echo -e "${YELLOW}[4/4] 推送镜像到 Docker Hub...${NC}"
docker push "${IMAGE}"
if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 镜像推送失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 镜像推送成功: ${IMAGE}"

# 推送 latest 标签（如果需要）
if [ "$PUSH_LATEST" == "true" ]; then
    echo ""
    echo -e "${YELLOW}推送 latest 标签...${NC}"
    docker push "${LATEST_IMAGE}"
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: latest 标签推送失败${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ latest 标签推送成功: ${LATEST_IMAGE}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "镜像已发布到 Docker Hub:"
echo "  - ${IMAGE}"
if [ "$PUSH_LATEST" == "true" ]; then
    echo "  - ${USERNAME}/${IMAGE_NAME}:latest"
fi
echo ""
echo "查看镜像: https://hub.docker.com/r/${USERNAME}/${IMAGE_NAME}"
echo ""
echo "使用 Helm 安装:"
echo "  helm install podmonitor-operator ./helm/podmonitor-operator \\"
echo "    --namespace podmonitor-system \\"
echo "    --create-namespace \\"
echo "    --set image.repository=${USERNAME}/${IMAGE_NAME} \\"
echo "    --set image.tag=${TAG}"
echo ""

