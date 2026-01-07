#!/bin/bash

# GitHub Container Registry 镜像发布脚本 (Linux/Mac)
# 使用方法: ./scripts/publish-ghcr.sh <github-username> [tag] [token]

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误: 请指定 GitHub 用户名${NC}"
    echo "使用方法: $0 <github-username> [tag] [token]"
    echo "示例: $0 geekzx v1.0.0"
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
TOKEN=$3

IMAGE_NAME="podmonitor-controller"
IMAGE="ghcr.io/${USERNAME}/${IMAGE_NAME}:${TAG}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}发布镜像到 GitHub Container Registry${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "GitHub 用户名: ${USERNAME}"
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

# 步骤 2: 登录 GHCR
echo -e "${YELLOW}[2/3] 登录 GitHub Container Registry...${NC}"
if [ -n "$TOKEN" ]; then
    echo ${TOKEN} | docker login ghcr.io -u ${USERNAME} --password-stdin
else
    echo -e "${YELLOW}提示: 如果没有提供 Token，将使用交互式登录${NC}"
    docker login ghcr.io
fi
if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 登录失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 登录成功${NC}"
echo ""

# 步骤 3: 推送镜像
echo -e "${YELLOW}[3/3] 推送镜像到 GHCR...${NC}"
docker push "${IMAGE}"
if [ $? -ne 0 ]; then
    echo -e "${RED}错误: 镜像推送失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 镜像推送成功${NC}"
echo ""

# 完成提示
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}发布完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${CYAN}镜像地址: https://github.com/users/${USERNAME}/packages/container/${IMAGE_NAME}${NC}"
echo -e "${YELLOW}重要提示: 记得在 GitHub 上将镜像设置为公开！${NC}"
echo ""
echo -e "${YELLOW}设置公开的步骤:${NC}"
echo "1. 访问: https://github.com/users/${USERNAME}/packages/container/${IMAGE_NAME}"
echo "2. 点击右侧的 'Package settings' (齿轮图标)"
echo "3. 滚动到底部 'Danger Zone'"
echo "4. 点击 'Change visibility' -> 选择 'Public'"
echo ""

