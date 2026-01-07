# 发布镜像到 GitHub Container Registry (GHCR) 指南

本指南介绍如何将 PodMonitor Operator 镜像发布到 GitHub Container Registry (GHCR) 并设置为公开。

## 前置要求

1. **GitHub 账号**
   - 如果没有账号，请访问 [GitHub](https://github.com/) 注册

2. **Docker 已安装并运行**
   - Windows: [Docker Desktop](https://www.docker.com/products/docker-desktop)
   - Linux: Docker Engine
   - 验证: `docker --version`

3. **GitHub Personal Access Token (PAT)**
   - 需要 `write:packages` 权限（用于推送）
   - 需要 `read:packages` 权限（用于拉取）

## 快速开始

### Windows PowerShell

```powershell
# 1. 设置镜像信息
$env:GITHUB_USERNAME = "geekzx"  # 替换为你的 GitHub 用户名
$env:IMAGE_NAME = "podmonitor-controller"
$env:IMAGE_TAG = "v1.0.0"
$env:IMAGE = "ghcr.io/$env:GITHUB_USERNAME/$env:IMAGE_NAME`:$env:IMAGE_TAG"

# 2. 构建镜像
docker build -t $env:IMAGE .

# 3. 登录 GHCR（使用 GitHub Personal Access Token）
$env:GHCR_TOKEN = "your_github_pat_token"  # 替换为你的 PAT
echo $env:GHCR_TOKEN | docker login ghcr.io -u $env:GITHUB_USERNAME --password-stdin

# 4. 推送镜像
docker push $env:IMAGE
```

### Linux/Mac

```bash
# 1. 设置镜像信息
export GITHUB_USERNAME="geekzx"  # 替换为你的 GitHub 用户名
export IMAGE_NAME="podmonitor-controller"
export IMAGE_TAG="v1.0.0"
export IMAGE="ghcr.io/${GITHUB_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# 2. 构建镜像
docker build -t ${IMAGE} .

# 3. 登录 GHCR（使用 GitHub Personal Access Token）
export GHCR_TOKEN="your_github_pat_token"  # 替换为你的 PAT
echo ${GHCR_TOKEN} | docker login ghcr.io -u ${GITHUB_USERNAME} --password-stdin

# 4. 推送镜像
docker push ${IMAGE}
```

## 详细步骤

### 步骤 1: 创建 GitHub Personal Access Token (PAT)

1. **登录 GitHub**
   - 访问 https://github.com/
   - 登录你的账号

2. **创建 Personal Access Token**
   - 点击右上角头像 -> **Settings**
   - 左侧菜单选择 **Developer settings**
   - 选择 **Personal access tokens** -> **Tokens (classic)**
   - 点击 **Generate new token** -> **Generate new token (classic)**
   - 输入 Token 名称（如：`GHCR Push Token`）
   - 选择过期时间
   - **勾选以下权限**：
     - `write:packages` - 推送和发布包
     - `read:packages` - 下载包
     - `delete:packages` - 删除包（可选）
   - 点击 **Generate token**
   - **重要**：复制生成的 Token（只显示一次，请妥善保存）

### 步骤 2: 构建镜像

#### 方式一：使用便捷脚本（推荐）

**Windows PowerShell：**

```powershell
.\scripts\publish-ghcr.ps1 -Username "geekzx" -Tag "v1.0.0"
```

**Linux/Mac：**

```bash
./scripts/publish-ghcr.sh geekzx v1.0.0
```

#### 方式二：手动构建

```powershell
# Windows PowerShell
$env:IMAGE = "ghcr.io/geekzx/podmonitor-controller:v1.0.0"
docker build -t $env:IMAGE .
```

```bash
# Linux/Mac
export IMAGE="ghcr.io/geekzx/podmonitor-controller:v1.0.0"
docker build -t ${IMAGE} .
```

### 步骤 3: 登录 GHCR

使用 GitHub Personal Access Token 登录：

```powershell
# Windows PowerShell
$env:GHCR_TOKEN = "your_github_pat_token"
echo $env:GHCR_TOKEN | docker login ghcr.io -u geekzx --password-stdin
```

```bash
# Linux/Mac
export GHCR_TOKEN="your_github_pat_token"
echo ${GHCR_TOKEN} | docker login ghcr.io -u geekzx --password-stdin
```

**或者交互式登录：**

```bash
docker login ghcr.io
# Username: geekzx
# Password: <输入你的 GitHub PAT>
```

### 步骤 4: 推送镜像

```powershell
# Windows PowerShell
docker push $env:IMAGE
```

```bash
# Linux/Mac
docker push ${IMAGE}
```

### 步骤 5: 将镜像设置为公开 ⭐

这是关键步骤！GHCR 的镜像默认是**私有**的，需要手动设置为公开。

#### 方法一：通过 GitHub 网页界面（推荐）

1. **访问你的 GitHub 仓库**
   - 打开 https://github.com/geekzx/pod-monitor（替换为你的仓库）

2. **进入 Packages 页面**
   - 点击仓库右侧的 **Packages** 链接
   - 或者直接访问：`https://github.com/users/geekzx/packages/container/podmonitor-controller`

3. **打开包设置**
   - 点击包名称（`podmonitor-controller`）
   - 点击右侧的 **Package settings**（齿轮图标）

4. **更改可见性**
   - 滚动到页面底部的 **Danger Zone**
   - 点击 **Change visibility**
   - 选择 **Public**
   - 确认更改

#### 方法二：通过 GitHub API

```bash
# 使用 curl 和 GitHub PAT
curl -X PATCH \
  -H "Authorization: token YOUR_GITHUB_PAT" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/packages/container/podmonitor-controller \
  -d '{"visibility":"public"}'
```

**注意**：需要将 `podmonitor-controller` 替换为你的实际包名。

#### 方法三：在推送时设置（需要仓库权限）

如果镜像属于某个 GitHub 仓库，可以在推送时通过注释设置：

```yaml
# 在 Dockerfile 或构建时添加标签
LABEL org.opencontainers.image.source=https://github.com/geekzx/pod-monitor
```

然后推送时使用：

```bash
docker push ghcr.io/geekzx/podmonitor-controller:v1.0.0
```

但这种方式仍然需要在 GitHub 上手动设置为公开。

## 验证镜像是否公开

### 方法一：通过网页访问

访问镜像页面，如果不需要登录就能看到，说明已公开：
```
https://github.com/users/geekzx/packages/container/podmonitor-controller
```

### 方法二：通过 Docker 拉取测试

```bash
# 不需要登录，直接拉取
docker pull ghcr.io/geekzx/podmonitor-controller:v1.0.0
```

如果不需要登录就能拉取，说明镜像已公开。

### 方法三：检查镜像信息

```bash
# 查看镜像标签
curl -s https://ghcr.io/v2/geekzx/podmonitor-controller/tags/list
```

## 使用公开镜像

镜像公开后，可以在 Kubernetes 中直接使用：

```yaml
image: ghcr.io/geekzx/podmonitor-controller:v1.0.0
```

或者在 Helm Chart 中：

```bash
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --set image.repository=ghcr.io/geekzx/podmonitor-controller \
  --set image.tag=v1.0.0
```

## 常见问题

### Q1: 推送时提示 "unauthorized"

**原因**：PAT 权限不足或 Token 已过期。

**解决**：
1. 检查 PAT 是否包含 `write:packages` 权限
2. 检查 Token 是否过期
3. 重新生成 Token 并登录

### Q2: 拉取时提示需要登录

**原因**：镜像仍然是私有的。

**解决**：
1. 按照步骤 5 将镜像设置为公开
2. 或者使用 PAT 登录后拉取

### Q3: 找不到 Packages 链接

**原因**：可能还没有推送过包，或者仓库设置问题。

**解决**：
1. 先推送一个镜像
2. 然后访问：`https://github.com/users/YOUR_USERNAME/packages`

### Q4: 如何删除镜像

1. 访问包的设置页面
2. 在 **Danger Zone** 中点击 **Delete this package**
3. 输入包名确认删除

## 自动化脚本

### Windows PowerShell 脚本

创建 `scripts/publish-ghcr.ps1`：

```powershell
# GitHub Container Registry 镜像发布脚本 (Windows PowerShell)
# 使用方法: .\scripts\publish-ghcr.ps1 -Username "geekzx" -Tag "v1.0.0" [-Token "your_pat"]

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Tag = "v1.0.0",
    [string]$Token = ""
)

$ImageName = "podmonitor-controller"
$Image = "ghcr.io/${Username}/${ImageName}:${Tag}"

Write-Host "构建镜像: $Image" -ForegroundColor Yellow
docker build -t $Image .

if ($LASTEXITCODE -eq 0) {
    Write-Host "镜像构建成功！" -ForegroundColor Green
    
    if ($Token) {
        Write-Host "登录 GHCR..." -ForegroundColor Yellow
        echo $Token | docker login ghcr.io -u $Username --password-stdin
    } else {
        Write-Host "登录 GHCR（交互式）..." -ForegroundColor Yellow
        docker login ghcr.io
    }
    
    Write-Host "推送镜像: $Image" -ForegroundColor Yellow
    docker push $Image
    
    Write-Host "完成！" -ForegroundColor Green
    Write-Host "镜像地址: https://github.com/users/$Username/packages/container/$ImageName" -ForegroundColor Cyan
    Write-Host "提示: 记得在 GitHub 上将镜像设置为公开！" -ForegroundColor Yellow
} else {
    Write-Host "镜像构建失败！" -ForegroundColor Red
    exit 1
}
```

### Linux/Mac Bash 脚本

创建 `scripts/publish-ghcr.sh`：

```bash
#!/bin/bash

# GitHub Container Registry 镜像发布脚本 (Linux/Mac)
# 使用方法: ./scripts/publish-ghcr.sh <github-username> [tag] [token]

set -e

if [ -z "$1" ]; then
    echo "使用方法: $0 <github-username> [tag] [token]"
    echo "示例: $0 geekzx v1.0.0"
    exit 1
fi

USERNAME=$1
TAG=${2:-v1.0.0}
TOKEN=$3

IMAGE_NAME="podmonitor-controller"
IMAGE="ghcr.io/${USERNAME}/${IMAGE_NAME}:${TAG}"

echo "构建镜像: ${IMAGE}"
docker build -t ${IMAGE} .

echo "镜像构建成功！"

if [ -n "$TOKEN" ]; then
    echo "登录 GHCR..."
    echo ${TOKEN} | docker login ghcr.io -u ${USERNAME} --password-stdin
else
    echo "登录 GHCR（交互式）..."
    docker login ghcr.io
fi

echo "推送镜像: ${IMAGE}"
docker push ${IMAGE}

echo "完成！"
echo "镜像地址: https://github.com/users/${USERNAME}/packages/container/${IMAGE_NAME}"
echo "提示: 记得在 GitHub 上将镜像设置为公开！"
```

## 总结

1. ✅ 构建镜像：`docker build -t ghcr.io/geekzx/podmonitor-controller:v1.0.0 .`
2. ✅ 登录 GHCR：使用 GitHub PAT
3. ✅ 推送镜像：`docker push ghcr.io/geekzx/podmonitor-controller:v1.0.0`
4. ⭐ **重要**：在 GitHub 上将镜像设置为公开

镜像公开后，任何人都可以拉取使用，无需登录。

