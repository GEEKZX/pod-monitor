#!/bin/bash

# Helm Chart 发布脚本
# 使用方法: ./scripts/publish-helm.sh [version]
# 例如: ./scripts/publish-helm.sh 0.1.0

set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 获取版本号
VERSION=${1:-""}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}PodMonitor Helm Chart 发布脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查 Helm 是否安装
if ! command -v helm &> /dev/null; then
    echo -e "${RED}错误: Helm 未安装${NC}"
    echo "请先安装 Helm: https://helm.sh/docs/intro/install/"
    exit 1
fi

# 检查是否在项目根目录
if [ ! -f "helm/podmonitor-operator/Chart.yaml" ]; then
    echo -e "${RED}错误: 请在项目根目录执行此脚本${NC}"
    exit 1
fi

# 获取当前 Chart 版本
CURRENT_VERSION=$(grep '^version:' helm/podmonitor-operator/Chart.yaml | awk '{print $2}')

if [ -z "$VERSION" ]; then
    VERSION=$CURRENT_VERSION
    echo -e "${YELLOW}使用 Chart.yaml 中的版本: ${VERSION}${NC}"
else
    echo -e "${YELLOW}使用指定版本: ${VERSION}${NC}"
    # 更新 Chart.yaml 中的版本
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version:.*/version: ${VERSION}/" helm/podmonitor-operator/Chart.yaml
    else
        sed -i "s/^version:.*/version: ${VERSION}/" helm/podmonitor-operator/Chart.yaml
    fi
    echo -e "${GREEN}✓ 已更新 Chart.yaml 版本为 ${VERSION}${NC}"
fi

# 步骤 1: 打包 Chart
echo ""
echo -e "${YELLOW}[1/5] 打包 Helm Chart...${NC}"
helm package ./helm/podmonitor-operator
CHART_FILE="podmonitor-operator-${VERSION}.tgz"

if [ ! -f "$CHART_FILE" ]; then
    echo -e "${RED}错误: 打包失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Chart 打包成功: ${CHART_FILE}${NC}"

# 步骤 2: 创建 charts 目录
echo ""
echo -e "${YELLOW}[2/5] 准备 charts 目录...${NC}"
mkdir -p charts

# 步骤 3: 移动文件
echo ""
echo -e "${YELLOW}[3/5] 移动 Chart 文件...${NC}"
mv "$CHART_FILE" charts/
echo -e "${GREEN}✓ 文件已移动到 charts/ 目录${NC}"

# 步骤 4: 生成/更新索引
echo ""
echo -e "${YELLOW}[4/5] 生成 Helm Repository 索引...${NC}"
if [ -f "charts/index.yaml" ]; then
    echo "合并到现有索引..."
    helm repo index charts/ --merge charts/index.yaml
else
    echo "创建新索引..."
    helm repo index charts/
fi
echo -e "${GREEN}✓ 索引文件已生成: charts/index.yaml${NC}"

# 步骤 5: 显示 Git 状态
echo ""
echo -e "${YELLOW}[5/5] Git 状态检查...${NC}"
echo ""
echo "以下文件已准备好提交:"
git status charts/ --short || echo "提示: 如果 charts/ 目录不在 Git 中，请先添加"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}打包完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "下一步操作:"
echo ""
echo "1. 检查生成的文件:"
echo "   ls -la charts/"
echo ""
echo "2. 添加并提交到 Git:"
echo "   git add charts/ helm/podmonitor-operator/Chart.yaml"
echo "   git commit -m \"Release Helm chart v${VERSION}\""
echo ""
echo "3. 推送到 GitHub:"
echo "   git push"
echo ""
echo "4. 确保 GitHub Pages 已启用（Settings -> Pages）"
echo ""
echo "5. 验证发布:"
echo "   helm repo add podmonitor https://your-username.github.io/your-repo/charts"
echo "   helm repo update"
echo "   helm search repo podmonitor"
echo ""

