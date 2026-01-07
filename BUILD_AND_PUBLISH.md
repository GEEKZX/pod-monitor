# 构建和发布镜像指南

本指南介绍如何构建 PodMonitor Operator 的 Docker 镜像并发布到不同的镜像仓库。

## 前置要求

- Docker 已安装并运行
- 镜像仓库账号（GitHub Container Registry、Docker Hub 或其他）

## 快速开始

### 发布到 GitHub Container Registry (GHCR)

```bash
# 1. 设置镜像信息
export GITHUB_USERNAME="geekzx"
export IMAGE_NAME="podmonitor-controller"
export IMAGE_TAG="v1.0.0"
export IMAGE="ghcr.io/${GITHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# 2. 构建镜像
docker build -t ${IMAGE} .

# 3. 登录 GHCR（使用 GitHub Personal Access Token）
export GHCR_TOKEN="your_github_pat_token"
echo ${GHCR_TOKEN} | docker login ghcr.io -u ${GITHUB_USERNAME} --password-stdin

# 4. 推送镜像
docker push ${IMAGE}
```

**Windows PowerShell：**

```powershell
$env:GITHUB_USERNAME = "geekzx"
$env:IMAGE_NAME = "podmonitor-controller"
$env:IMAGE_TAG = "v1.0.0"
$env:IMAGE = "ghcr.io/$env:GITHUB_USERNAME/$env:IMAGE_NAME`:$env:IMAGE_TAG"

docker build -t $env:IMAGE .
$env:GHCR_TOKEN = "your_github_pat_token"
echo $env:GHCR_TOKEN | docker login ghcr.io -u $env:GITHUB_USERNAME --password-stdin
docker push $env:IMAGE
```

**使用脚本：**

```bash
# Linux/Mac
./scripts/publish-ghcr.sh geekzx v1.0.0

# Windows PowerShell
.\scripts\publish-ghcr.ps1 -Username "geekzx" -Tag "v1.0.0"
```

### 发布到 Docker Hub

```bash
# 1. 设置镜像信息
export DOCKERHUB_USERNAME="your-username"
export IMAGE_TAG="v1.0.0"
export IMAGE="${DOCKERHUB_USERNAME}/podmonitor-controller:${IMAGE_TAG}"

# 2. 构建镜像
docker build -t ${IMAGE} .

# 3. 登录 Docker Hub
docker login

# 4. 推送镜像
docker push ${IMAGE}
```

**Windows PowerShell：**

```powershell
$env:DOCKERHUB_USERNAME = "your-username"
$env:IMAGE_TAG = "v1.0.0"
$env:IMAGE = "$env:DOCKERHUB_USERNAME/podmonitor-controller:$env:IMAGE_TAG"

docker build -t $env:IMAGE .
docker login
docker push $env:IMAGE
```

**使用脚本：**

```bash
# Linux/Mac
./scripts/publish-dockerhub.sh your-username v1.0.0

# Windows PowerShell
.\scripts\publish-dockerhub.ps1 -Username "your-username" -Tag "v1.0.0"
```

## 详细步骤

### 创建 GitHub Personal Access Token (GHCR)

1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token" -> "Generate new token (classic)"
3. 输入 Token 名称，选择过期时间
4. 勾选权限：
   - `write:packages` - 推送和发布包
   - `read:packages` - 下载包
5. 点击 "Generate token" 并复制 Token

### 将 GHCR 镜像设置为公开

1. 访问 https://github.com/users/geekzx/packages/container/podmonitor-controller
2. 点击右侧的 "Package settings"（齿轮图标）
3. 滚动到底部 "Danger Zone"
4. 点击 "Change visibility" -> 选择 "Public"


## 使用脚本

项目提供了便捷的构建和发布脚本：

### 构建镜像脚本

```bash
# Linux/Mac
REGISTRY="ghcr.io" NAMESPACE="geekzx" TAG="v1.0.0" ./scripts/build-image.sh

# Windows PowerShell
.\scripts\build-image.ps1 -Registry "ghcr.io" -Namespace "geekzx" -Tag "v1.0.0"
```

### 发布到 GHCR 脚本

```bash
# Linux/Mac
./scripts/publish-ghcr.sh geekzx v1.0.0

# Windows PowerShell
.\scripts\publish-ghcr.ps1 -Username "geekzx" -Tag "v1.0.0" -Token "your_pat"
```

### 发布到 Docker Hub 脚本

```bash
# Linux/Mac
./scripts/publish-dockerhub.sh your-username v1.0.0

# Windows PowerShell
.\scripts\publish-dockerhub.ps1 -Username "your-username" -Tag "v1.0.0"
```

## 常见问题

### 构建失败

```bash
# 检查 Dockerfile
cat Dockerfile

# 检查 Go 版本
go version

# 清理构建缓存
docker builder prune
```

### 推送失败

```bash
# 检查登录状态
docker login ghcr.io

# 检查镜像标签
docker images | grep podmonitor-controller

# 检查权限
docker pull ghcr.io/geekzx/podmonitor-controller:v1.0.0
```

### 镜像拉取失败

```bash
# 检查镜像是否公开（GHCR）
# 访问 https://github.com/users/geekzx/packages/container/podmonitor-controller

# 检查镜像标签
docker pull ghcr.io/geekzx/podmonitor-controller:v1.0.0
```

## 相关文档

- [Helm 部署指南](./HELM_DEPLOY.md)
- [项目 README](./README.md)

