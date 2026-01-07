# 发布镜像到 Docker Hub 指南

本指南详细介绍如何将 PodMonitor Operator 镜像发布到 Docker Hub。

## 前置要求

1. **Docker Hub 账号**
   - 如果没有账号，请访问 [Docker Hub](https://hub.docker.com/) 注册
   - 验证邮箱（首次注册需要）

2. **Docker 已安装并运行**
   - Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Linux: Docker Engine
   - 验证: `docker --version`

## 快速开始

### Windows PowerShell

```powershell
# 1. 设置镜像信息（使用你的 Docker Hub 用户名）
$env:DOCKERHUB_USERNAME = "your-username"  # 替换为你的 Docker Hub 用户名
$env:IMAGE_TAG = "v1.0.0"
$env:IMAGE = "$env:DOCKERHUB_USERNAME/podmonitor-controller:$env:IMAGE_TAG"

# 2. 构建镜像
docker build -t $env:IMAGE .

# 3. 登录 Docker Hub
docker login

# 4. 推送镜像
docker push $env:IMAGE
```

### Linux/Mac

```bash
# 1. 设置镜像信息（使用你的 Docker Hub 用户名）
export DOCKERHUB_USERNAME="your-username"  # 替换为你的 Docker Hub 用户名
export IMAGE_TAG="v1.0.0"
export IMAGE="${DOCKERHUB_USERNAME}/podmonitor-controller:${IMAGE_TAG}"

# 2. 构建镜像
docker build -t ${IMAGE} .

# 3. 登录 Docker Hub
docker login

# 4. 推送镜像
docker push ${IMAGE}
```

## 详细步骤

### 步骤 1: 准备 Docker Hub 账号

1. **注册账号**（如果还没有）
   - 访问 https://hub.docker.com/
   - 点击 "Sign Up" 注册
   - 验证邮箱

2. **创建仓库**（可选）
   - 登录 Docker Hub
   - 点击 "Create Repository"
   - 仓库名称：`podmonitor-controller`（或你喜欢的名字）
   - 设置为 Public（公开）或 Private（私有）
   - 点击 "Create"

   **注意**：Docker Hub 会自动创建仓库，所以这一步是可选的。首次推送时会自动创建。

### 步骤 2: 构建镜像

#### 方式一：使用便捷脚本（推荐）

**Windows PowerShell：**

```powershell
# 使用构建脚本
.\scripts\build-image.ps1 -Registry "docker.io" -Namespace "your-username" -Tag "v1.0.0"
```

**Linux/Mac：**

```bash
# 添加执行权限（首次使用）
chmod +x scripts/build-image.sh

# 使用构建脚本
REGISTRY="docker.io" NAMESPACE="your-username" TAG="v1.0.0" ./scripts/build-image.sh
```

#### 方式二：手动构建

**Windows PowerShell：**

```powershell
# 设置变量
$env:DOCKERHUB_USERNAME = "your-username"
$env:IMAGE_TAG = "v1.0.0"
$env:IMAGE = "$env:DOCKERHUB_USERNAME/podmonitor-controller:$env:IMAGE_TAG"

# 构建镜像
docker build -t $env:IMAGE .
```

**Linux/Mac：**

```bash
# 设置变量
export DOCKERHUB_USERNAME="your-username"
export IMAGE_TAG="v1.0.0"
export IMAGE="${DOCKERHUB_USERNAME}/podmonitor-controller:${IMAGE_TAG}"

# 构建镜像
docker build -t ${IMAGE} .
```

### 步骤 3: 登录 Docker Hub

**Windows PowerShell：**

```powershell
# 交互式登录（推荐）
docker login

# 会提示输入：
# Username: your-username
# Password: your-password
```

**Linux/Mac：**

```bash
# 交互式登录（推荐）
docker login

# 会提示输入：
# Username: your-username
# Password: your-password
```

**使用访问令牌登录（推荐用于 CI/CD）：**

Docker Hub 推荐使用访问令牌（Access Token）而不是密码：

1. 登录 Docker Hub
2. 点击右上角头像 -> Account Settings
3. 选择 Security -> New Access Token
4. 输入 Token 描述，选择权限（Read & Write）
5. 复制生成的 Token（只显示一次）

然后使用 Token 登录：

```powershell
# Windows PowerShell
echo "your-access-token" | docker login --username="your-username" --password-stdin
```

```bash
# Linux/Mac
echo "your-access-token" | docker login --username="your-username" --password-stdin
```

### 步骤 4: 推送镜像

**Windows PowerShell：**

```powershell
# 推送镜像
docker push $env:IMAGE

# 或者使用完整地址
docker push your-username/podmonitor-controller:v1.0.0
```

**Linux/Mac：**

```bash
# 推送镜像
docker push ${IMAGE}

# 或者使用完整地址
docker push your-username/podmonitor-controller:v1.0.0
```

推送完成后，可以在 Docker Hub 上查看你的镜像：
```
https://hub.docker.com/r/your-username/podmonitor-controller
```

### 步骤 5: 验证镜像

**Windows PowerShell：**

```powershell
# 从 Docker Hub 拉取镜像验证
docker pull $env:IMAGE

# 查看镜像信息
docker inspect $env:IMAGE

# 查看镜像标签
docker images | Select-String "podmonitor-controller"
```

**Linux/Mac：**

```bash
# 从 Docker Hub 拉取镜像验证
docker pull ${IMAGE}

# 查看镜像信息
docker inspect ${IMAGE}

# 查看镜像标签
docker images | grep podmonitor-controller
```

## 推送多个标签

通常我们会推送多个标签，如 `latest` 和版本号：

**Windows PowerShell：**

```powershell
$env:DOCKERHUB_USERNAME = "your-username"
$env:IMAGE_TAG = "v1.0.0"

# 构建并标记为多个标签
docker build -t "$env:DOCKERHUB_USERNAME/podmonitor-controller:$env:IMAGE_TAG" .
docker tag "$env:DOCKERHUB_USERNAME/podmonitor-controller:$env:IMAGE_TAG" "$env:DOCKERHUB_USERNAME/podmonitor-controller:latest"

# 推送所有标签
docker push "$env:DOCKERHUB_USERNAME/podmonitor-controller:$env:IMAGE_TAG"
docker push "$env:DOCKERHUB_USERNAME/podmonitor-controller:latest"
```

**Linux/Mac：**

```bash
export DOCKERHUB_USERNAME="your-username"
export IMAGE_TAG="v1.0.0"

# 构建并标记为多个标签
docker build -t "${DOCKERHUB_USERNAME}/podmonitor-controller:${IMAGE_TAG}" .
docker tag "${DOCKERHUB_USERNAME}/podmonitor-controller:${IMAGE_TAG}" "${DOCKERHUB_USERNAME}/podmonitor-controller:latest"

# 推送所有标签
docker push "${DOCKERHUB_USERNAME}/podmonitor-controller:${IMAGE_TAG}"
docker push "${DOCKERHUB_USERNAME}/podmonitor-controller:latest"
```

## 使用 Helm 安装时指定 Docker Hub 镜像

发布到 Docker Hub 后，使用 Helm 安装时可以这样指定：

```bash
# 安装时指定 Docker Hub 镜像
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=your-username/podmonitor-controller \
  --set image.tag=v1.0.0
```

或者使用 values 文件：

```yaml
# my-values.yaml
image:
  repository: your-username/podmonitor-controller
  tag: v1.0.0
  pullPolicy: IfNotPresent
```

然后安装：

```bash
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  -f my-values.yaml
```

## 自动化脚本

### Windows PowerShell 完整脚本

创建 `scripts/publish-dockerhub.ps1`：

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Tag = "v1.0.0",
    [switch]$PushLatest = $false
)

$ImageName = "podmonitor-controller"
$Image = "${Username}/${ImageName}:${Tag}"

Write-Host "构建镜像: $Image" -ForegroundColor Green
docker build -t $Image .

if ($LASTEXITCODE -eq 0) {
    Write-Host "镜像构建成功！" -ForegroundColor Green
    
    # 如果推送 latest 标签
    if ($PushLatest) {
        $LatestImage = "${Username}/${ImageName}:latest"
        docker tag $Image $LatestImage
        Write-Host "标记为 latest: $LatestImage" -ForegroundColor Yellow
    }
    
    Write-Host "登录 Docker Hub..." -ForegroundColor Yellow
    docker login
    
    Write-Host "推送镜像: $Image" -ForegroundColor Yellow
    docker push $Image
    
    if ($PushLatest) {
        Write-Host "推送 latest 标签..." -ForegroundColor Yellow
        docker push $LatestImage
    }
    
    Write-Host "完成！" -ForegroundColor Green
    Write-Host "镜像地址: https://hub.docker.com/r/$Username/$ImageName" -ForegroundColor Cyan
} else {
    Write-Host "镜像构建失败！" -ForegroundColor Red
    exit 1
}
```

使用方法：

```powershell
.\scripts\publish-dockerhub.ps1 -Username "your-username" -Tag "v1.0.0" -PushLatest
```

### Linux/Mac Bash 脚本

创建 `scripts/publish-dockerhub.sh`：

```bash
#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "使用方法: $0 <dockerhub-username> [tag] [--latest]"
    echo "示例: $0 myusername v1.0.0 --latest"
    exit 1
fi

USERNAME=$1
TAG=${2:-v1.0.0}
PUSH_LATEST=false

if [ "$3" == "--latest" ]; then
    PUSH_LATEST=true
fi

IMAGE_NAME="podmonitor-controller"
IMAGE="${USERNAME}/${IMAGE_NAME}:${TAG}"

echo "构建镜像: ${IMAGE}"
docker build -t ${IMAGE} .

echo "镜像构建成功！"

# 如果推送 latest 标签
if [ "$PUSH_LATEST" == "true" ]; then
    LATEST_IMAGE="${USERNAME}/${IMAGE_NAME}:latest"
    docker tag ${IMAGE} ${LATEST_IMAGE}
    echo "标记为 latest: ${LATEST_IMAGE}"
fi

echo "登录 Docker Hub..."
docker login

echo "推送镜像: ${IMAGE}"
docker push ${IMAGE}

if [ "$PUSH_LATEST" == "true" ]; then
    echo "推送 latest 标签..."
    docker push ${LATEST_IMAGE}
fi

echo "完成！"
echo "镜像地址: https://hub.docker.com/r/${USERNAME}/${IMAGE_NAME}"
```

使用方法：

```bash
chmod +x scripts/publish-dockerhub.sh
./scripts/publish-dockerhub.sh your-username v1.0.0 --latest
```

## 常见问题

### 1. 登录失败：用户名或密码错误

**问题**：`Error: Cannot perform an interactive login from a non TTY device`

**解决方案**：
- 确保在交互式终端中运行 `docker login`
- 如果使用脚本，确保脚本支持交互式输入

### 2. 推送失败：权限不足

**问题**：`denied: requested access to the resource is denied`

**解决方案**：
- 检查镜像名称是否正确（格式：`username/repository:tag`）
- 确保已登录正确的账号
- 检查仓库是否为私有（私有仓库需要付费账户）

### 3. 推送失败：仓库不存在

**问题**：`repository name must be lowercase`

**解决方案**：
- Docker Hub 仓库名称必须是小写
- 不能包含特殊字符（除了连字符和下划线）
- 确保用户名和仓库名都是小写

### 4. 推送很慢

**问题**：推送镜像到 Docker Hub 很慢

**解决方案**：
- Docker Hub 免费账户有速率限制
- 考虑使用镜像加速器（如果在中国）
- 或者使用其他镜像仓库（如阿里云 ACR）

### 5. 如何删除镜像

在 Docker Hub 网页上：
1. 登录 Docker Hub
2. 进入你的仓库
3. 点击 "Tags" 标签
4. 选择要删除的标签，点击删除

**注意**：删除镜像标签不会立即释放空间，Docker Hub 会定期清理。

## Docker Hub 限制

### 免费账户限制

- **仓库数量**：1 个私有仓库，无限公开仓库
- **拉取速率**：200 pulls per 6 hours（匿名用户），5000 pulls per 6 hours（认证用户）
- **推送速率**：无限制
- **存储空间**：无限制（但建议合理使用）

### 付费账户

如果需要更多私有仓库或更高的拉取速率，可以考虑升级到付费账户。

## 最佳实践

1. **使用语义化版本号**：如 `v1.0.0`、`v1.1.0` 等
2. **同时推送 latest 标签**：方便用户使用最新版本
3. **添加镜像描述**：在 Docker Hub 上添加 README 描述镜像用途
4. **使用多阶段构建**：保持镜像体积小（当前 Dockerfile 已使用）
5. **定期更新**：及时推送新版本和安全更新

## 下一步

镜像发布到 Docker Hub 后：

1. **在 Docker Hub 上添加描述**：
   - 登录 Docker Hub
   - 进入仓库页面
   - 点击 "Edit" 添加描述和 README

2. **使用 Helm 安装**：
   ```bash
   helm install podmonitor-operator ./helm/podmonitor-operator \
     --namespace podmonitor-system \
     --create-namespace \
     --set image.repository=your-username/podmonitor-controller \
     --set image.tag=v1.0.0
   ```

3. **分享给其他人**：
   - 公开仓库可以直接分享链接
   - 其他人可以直接使用：`docker pull your-username/podmonitor-controller:v1.0.0`

## 相关文档

- [镜像构建指南](./BUILD_IMAGE.md)
- [Helm 部署指南](./HELM_DEPLOY.md)
- [从 Helm 仓库安装](./INSTALL_FROM_HELM.md)

