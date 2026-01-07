# Docker Hub 镜像发布脚本 (Windows PowerShell)
# 使用方法: .\scripts\publish-dockerhub.ps1 -Username "your-username" -Tag "v1.0.0" [-PushLatest]

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Tag = "v1.0.0",
    [switch]$PushLatest = $false
)

# 颜色输出
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# 检查 Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-ColorOutput Red "错误: Docker 未安装或不在 PATH 中"
    exit 1
}

# 设置镜像信息
$ImageName = "podmonitor-controller"
$Image = "${Username}/${ImageName}:${Tag}"

Write-Output ""
Write-ColorOutput Green "========================================"
Write-ColorOutput Green "发布镜像到 Docker Hub"
Write-ColorOutput Green "========================================"
Write-Output ""
Write-Output "Docker Hub 用户名: $Username"
Write-Output "镜像标签: $Tag"
Write-Output "完整地址: $Image"
if ($PushLatest) {
    Write-Output "同时推送 latest 标签: 是"
}
Write-Output ""

# 步骤 1: 构建镜像
Write-ColorOutput Yellow "[1/4] 构建 Docker 镜像..."
docker build -t $Image .
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "错误: 镜像构建失败"
    exit 1
}
Write-ColorOutput Green "✓ 镜像构建成功"
Write-Output ""

# 步骤 2: 标记 latest 标签（如果需要）
if ($PushLatest) {
    Write-ColorOutput Yellow "[2/4] 标记 latest 标签..."
    $LatestImage = "${Username}/${ImageName}:latest"
    docker tag $Image $LatestImage
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "错误: 标记 latest 失败"
        exit 1
    }
    Write-ColorOutput Green "✓ latest 标签已创建"
    Write-Output ""
} else {
    Write-ColorOutput Yellow "[2/4] 跳过 latest 标签（使用 -PushLatest 参数可同时推送 latest）"
    Write-Output ""
}

# 步骤 3: 登录 Docker Hub
Write-ColorOutput Yellow "[3/4] 登录 Docker Hub..."
Write-Output "请输入 Docker Hub 登录信息（或按 Ctrl+C 取消）"
docker login
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "错误: Docker Hub 登录失败"
    Write-Output "请手动执行: docker login"
    exit 1
}
Write-ColorOutput Green "✓ 登录成功"
Write-Output ""

# 步骤 4: 推送镜像
Write-ColorOutput Yellow "[4/4] 推送镜像到 Docker Hub..."
docker push $Image
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "错误: 镜像推送失败"
    exit 1
}
Write-ColorOutput Green "✓ 镜像推送成功: $Image"

# 推送 latest 标签（如果需要）
if ($PushLatest) {
    Write-Output ""
    Write-ColorOutput Yellow "推送 latest 标签..."
    docker push $LatestImage
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "错误: latest 标签推送失败"
        exit 1
    }
    Write-ColorOutput Green "✓ latest 标签推送成功: $LatestImage"
}

Write-Output ""
Write-ColorOutput Green "========================================"
Write-ColorOutput Green "完成！"
Write-ColorOutput Green "========================================"
Write-Output ""
Write-Output "镜像已发布到 Docker Hub:"
Write-Output "  - $Image"
if ($PushLatest) {
    Write-Output "  - ${Username}/${ImageName}:latest"
}
Write-Output ""
Write-Output "查看镜像: https://hub.docker.com/r/$Username/$ImageName"
Write-Output ""
Write-Output "使用 Helm 安装:"
Write-Output "  helm install podmonitor-operator ./helm/podmonitor-operator \"
Write-Output "    --namespace podmonitor-system \"
Write-Output "    --create-namespace \"
Write-Output "    --set image.repository=$Username/$ImageName \"
Write-Output "    --set image.tag=$Tag"
Write-Output ""

