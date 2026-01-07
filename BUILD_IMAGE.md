# Docker 镜像打包指南

本指南介绍如何构建和推送 PodMonitor Operator 的 Docker 镜像。

## 前置要求

1. **Docker 已安装并运行**
   - Windows: 安装 [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Linux: 安装 Docker Engine
   - 验证: `docker --version`

2. **Go 环境**（可选，如果使用 make 命令）
   - 已安装 Go 1.21+
   - 验证: `go version`

3. **镜像仓库账号**（用于推送镜像）
   - 阿里云 ACR
   - Docker Hub
   - 或其他容器镜像仓库

## 快速开始

### Windows PowerShell 方式

```powershell
# 1. 设置镜像地址变量
$env:IMAGE_REGISTRY = "registry.cn-hangzhou.aliyuncs.com"
$env:IMAGE_NAMESPACE = "your-namespace"  # 替换为你的命名空间
$env:IMAGE_NAME = "podmonitor-controller"
$env:IMAGE_TAG = "v1.0.0"
$env:IMAGE = "$env:IMAGE_REGISTRY/$env:IMAGE_NAMESPACE/$env:IMAGE_NAME`:$env:IMAGE_TAG"

# 2. 构建镜像
docker build -t $env:IMAGE .

# 3. 登录镜像仓库
docker login $env:IMAGE_REGISTRY

# 4. 推送镜像
docker push $env:IMAGE
```

### Linux/Mac Bash 方式

```bash
# 1. 设置镜像地址变量
export IMAGE_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
export IMAGE_NAMESPACE="your-namespace"  # 替换为你的命名空间
export IMAGE_NAME="podmonitor-controller"
export IMAGE_TAG="v1.0.0"
export IMAGE="${IMAGE_REGISTRY}/${IMAGE_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"

# 2. 构建镜像
docker build -t ${IMAGE} .

# 3. 登录镜像仓库
docker login ${IMAGE_REGISTRY}

# 4. 推送镜像
docker push ${IMAGE}
```

## 详细步骤

### 步骤 1: 准备镜像仓库信息

根据你使用的镜像仓库，设置相应的地址：

#### 阿里云 ACR

```powershell
# Windows PowerShell
$env:IMAGE_REGISTRY = "registry.cn-hangzhou.aliyuncs.com"  # 根据地域选择
$env:IMAGE_NAMESPACE = "your-namespace"  # 你的 ACR 命名空间
```

```bash
# Linux/Mac
export IMAGE_REGISTRY="registry.cn-hangzhou.aliyuncs.com"  # 根据地域选择
export IMAGE_NAMESPACE="your-namespace"  # 你的 ACR 命名空间
```

**常见地域地址：**
- 杭州: `registry.cn-hangzhou.aliyuncs.com`
- 北京: `registry.cn-beijing.aliyuncs.com`
- 上海: `registry.cn-shanghai.aliyuncs.com`
- 深圳: `registry.cn-shenzhen.aliyuncs.com`

#### Docker Hub

```powershell
# Windows PowerShell
$env:IMAGE_REGISTRY = "docker.io"
$env:IMAGE_NAMESPACE = "your-username"  # 你的 Docker Hub 用户名
```

```bash
# Linux/Mac
export IMAGE_REGISTRY="docker.io"
export IMAGE_NAMESPACE="your-username"  # 你的 Docker Hub 用户名
```

#### 其他私有仓库

```powershell
# Windows PowerShell
$env:IMAGE_REGISTRY = "your-registry.com"
$env:IMAGE_NAMESPACE = "your-namespace"
```

```bash
# Linux/Mac
export IMAGE_REGISTRY="your-registry.com"
export IMAGE_NAMESPACE="your-namespace"
```

### 步骤 2: 构建镜像

#### 方式一：使用 Docker 命令（推荐）

```powershell
# Windows PowerShell
$env:IMAGE = "$env:IMAGE_REGISTRY/$env:IMAGE_NAMESPACE/podmonitor-controller:v1.0.0"
docker build -t $env:IMAGE .
```

```bash
# Linux/Mac
export IMAGE="${IMAGE_REGISTRY}/${IMAGE_NAMESPACE}/podmonitor-controller:v1.0.0"
docker build -t ${IMAGE} .
```

#### 方式二：使用 Makefile（需要安装 make）

```powershell
# Windows PowerShell（需要安装 make，如通过 Chocolatey: choco install make）
$env:IMG = "$env:IMAGE_REGISTRY/$env:IMAGE_NAMESPACE/podmonitor-controller:v1.0.0"
make docker-build IMG=$env:IMG
```

```bash
# Linux/Mac
export IMG="${IMAGE_REGISTRY}/${IMAGE_NAMESPACE}/podmonitor-controller:v1.0.0"
make docker-build IMG=${IMG}
```

#### 构建过程说明

构建过程包括两个阶段：

1. **构建阶段**：使用 `golang:1.21` 镜像编译 Go 代码
2. **运行阶段**：使用 `distroless` 镜像作为运行时（更安全、更小）

构建完成后，可以验证镜像：

```powershell
# Windows PowerShell
docker images | Select-String "podmonitor-controller"
```

```bash
# Linux/Mac
docker images | grep podmonitor-controller
```

### 步骤 3: 测试镜像（可选）

在推送之前，可以测试镜像是否能正常运行：

```powershell
# Windows PowerShell
docker run --rm $env:IMAGE --help
```

```bash
# Linux/Mac
docker run --rm ${IMAGE} --help
```

### 步骤 4: 登录镜像仓库

#### 阿里云 ACR

```powershell
# Windows PowerShell
# 方式 1: 交互式登录（推荐）
docker login $env:IMAGE_REGISTRY

# 方式 2: 使用 AccessKey（适合 CI/CD）
docker login --username="your_access_key_id" --password="your_access_key_secret" $env:IMAGE_REGISTRY
```

```bash
# Linux/Mac
# 方式 1: 交互式登录（推荐）
docker login ${IMAGE_REGISTRY}

# 方式 2: 使用 AccessKey（适合 CI/CD）
echo "your_access_key_secret" | docker login --username="your_access_key_id" --password-stdin ${IMAGE_REGISTRY}
```

#### Docker Hub

```powershell
# Windows PowerShell
# 方式 1: 交互式登录（推荐）
docker login

# 方式 2: 使用访问令牌（推荐用于 CI/CD）
echo "your-access-token" | docker login --username="your-username" --password-stdin
```

```bash
# Linux/Mac
# 方式 1: 交互式登录（推荐）
docker login

# 方式 2: 使用访问令牌（推荐用于 CI/CD）
echo "your-access-token" | docker login --username="your-username" --password-stdin
```

**Docker Hub 访问令牌获取方法：**
1. 登录 Docker Hub
2. 点击右上角头像 -> Account Settings
3. 选择 Security -> New Access Token
4. 输入描述，选择权限（Read & Write）
5. 复制生成的 Token（只显示一次）

### 步骤 5: 推送镜像

```powershell
# Windows PowerShell
docker push $env:IMAGE
```

```bash
# Linux/Mac
docker push ${IMAGE}
```

推送完成后，可以在镜像仓库控制台查看镜像。

### 步骤 6: 验证镜像

```powershell
# Windows PowerShell
# 从仓库拉取镜像验证
docker pull $env:IMAGE

# 查看镜像信息
docker inspect $env:IMAGE
```

```bash
# Linux/Mac
# 从仓库拉取镜像验证
docker pull ${IMAGE}

# 查看镜像信息
docker inspect ${IMAGE}
```

## 使用 Makefile 构建（Linux/Mac）

如果你在 Linux 或 Mac 上，可以使用 Makefile 提供的便捷命令：

```bash
# 设置镜像地址
export IMG="registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller:v1.0.0"

# 构建镜像（会自动运行测试）
make docker-build IMG=${IMG}

# 推送镜像
make docker-push IMG=${IMG}
```

## 多架构构建（高级）

如果需要构建多架构镜像（如 amd64 和 arm64）：

```bash
# 安装 buildx（Docker Desktop 已包含）
docker buildx create --use

# 构建并推送多架构镜像
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t ${IMAGE} \
  --push \
  .
```

## 构建优化

### 使用构建缓存

Docker 会自动使用缓存加速构建。如果依赖没有变化，构建会很快。

### 查看构建过程

```powershell
# Windows PowerShell
docker build --progress=plain -t $env:IMAGE .
```

```bash
# Linux/Mac
docker build --progress=plain -t ${IMAGE} .
```

### 清理构建缓存

如果遇到构建问题，可以清理缓存：

```powershell
# Windows PowerShell
docker builder prune
```

```bash
# Linux/Mac
docker builder prune
```

## 常见问题

### 1. 构建失败：无法下载依赖

**问题**：`go mod download` 失败

**解决方案**：
- 检查网络连接
- 如果在中国，可能需要配置 Go 代理：
  ```powershell
  # Windows PowerShell
  $env:GOPROXY = "https://goproxy.cn,direct"
  ```

  ```bash
  # Linux/Mac
  export GOPROXY="https://goproxy.cn,direct"
  ```

### 2. 推送失败：认证错误

**问题**：`unauthorized: authentication required`

**解决方案**：
- 确保已正确登录：`docker login <registry>`
- 检查镜像地址是否正确
- 检查是否有推送权限

### 3. 镜像太大

**问题**：镜像体积较大

**解决方案**：
- 当前 Dockerfile 已使用多阶段构建和 distroless 镜像，体积已优化
- 如需进一步优化，可以考虑：
  - 使用更小的基础镜像
  - 移除不必要的文件

### 4. Windows 构建慢

**问题**：在 Windows 上构建很慢

**解决方案**：
- 确保 Docker Desktop 使用 WSL2 后端
- 增加 Docker Desktop 的资源分配（CPU、内存）
- 考虑在 Linux 环境或 CI/CD 中构建

## 自动化脚本

### Windows PowerShell 脚本

创建 `scripts/build-image.ps1`：

```powershell
param(
    [string]$Registry = "registry.cn-hangzhou.aliyuncs.com",
    [string]$Namespace = "your-namespace",
    [string]$Tag = "v1.0.0"
)

$Image = "$Registry/$Namespace/podmonitor-controller:$Tag"

Write-Host "构建镜像: $Image" -ForegroundColor Green
docker build -t $Image .

if ($LASTEXITCODE -eq 0) {
    Write-Host "镜像构建成功！" -ForegroundColor Green
    Write-Host "推送镜像: $Image" -ForegroundColor Yellow
    docker push $Image
} else {
    Write-Host "镜像构建失败！" -ForegroundColor Red
    exit 1
}
```

使用方法：

```powershell
.\scripts\build-image.ps1 -Registry "registry.cn-hangzhou.aliyuncs.com" -Namespace "your-namespace" -Tag "v1.0.0"
```

### Linux/Mac Bash 脚本

创建 `scripts/build-image.sh`：

```bash
#!/bin/bash

set -e

REGISTRY="${REGISTRY:-registry.cn-hangzhou.aliyuncs.com}"
NAMESPACE="${NAMESPACE:-your-namespace}"
TAG="${TAG:-v1.0.0}"

IMAGE="${REGISTRY}/${NAMESPACE}/podmonitor-controller:${TAG}"

echo "构建镜像: ${IMAGE}"
docker build -t ${IMAGE} .

echo "推送镜像: ${IMAGE}"
docker push ${IMAGE}

echo "完成！"
```

使用方法：

```bash
chmod +x scripts/build-image.sh
REGISTRY="registry.cn-hangzhou.aliyuncs.com" NAMESPACE="your-namespace" TAG="v1.0.0" ./scripts/build-image.sh
```

## 下一步

镜像构建并推送完成后，你可以：

1. **使用 Helm 安装**：参考 [INSTALL_FROM_HELM.md](./INSTALL_FROM_HELM.md)
2. **直接部署**：参考 [DEPLOY_ALIYUN.md](./DEPLOY_ALIYUN.md)
3. **配置 CI/CD**：将构建流程集成到 CI/CD 中

## 发布到 Docker Hub

详细说明请参考：[发布到 Docker Hub 指南](./PUBLISH_TO_DOCKERHUB.md)

快速发布到 Docker Hub：

**Windows PowerShell：**
```powershell
.\scripts\publish-dockerhub.ps1 -Username "your-username" -Tag "v1.0.0" -PushLatest
```

**Linux/Mac：**
```bash
chmod +x scripts/publish-dockerhub.sh
./scripts/publish-dockerhub.sh your-username v1.0.0 --latest
```

## 相关文档

- [发布到 Docker Hub 指南](./PUBLISH_TO_DOCKERHUB.md) - 详细的 Docker Hub 发布说明
- [Helm 部署指南](./HELM_DEPLOY.md)
- [从 Helm 仓库安装](./INSTALL_FROM_HELM.md)
- [阿里云部署指南](./DEPLOY_ALIYUN.md)

