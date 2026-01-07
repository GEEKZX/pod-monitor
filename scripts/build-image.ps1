# Docker 镜像构建和推送脚本 (Windows PowerShell)
# 使用方法: .\scripts\build-image.ps1 -Registry "registry.cn-hangzhou.aliyuncs.com" -Namespace "your-namespace" -Tag "v1.0.0"

param(
    [string]$Registry = "registry.cn-hangzhou.aliyuncs.com",
    [string]$Namespace = "",
    [string]$Tag = "v1.0.0",
    [switch]$SkipPush = $false
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

# 检查参数
if ([string]::IsNullOrEmpty($Namespace)) {
    Write-ColorOutput Red "错误: 请指定命名空间"
    Write-Output "使用方法: .\scripts\build-image.ps1 -Registry `"registry.cn-hangzhou.aliyuncs.com`" -Namespace `"your-namespace`" -Tag `"v1.0.0`""
    exit 1
}

# 检查 Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-ColorOutput Red "错误: Docker 未安装或不在 PATH 中"
    exit 1
}

# 设置镜像地址
$ImageName = "podmonitor-controller"
$Image = "$Registry/$Namespace/$ImageName`:$Tag"

Write-Output ""
Write-ColorOutput Green "========================================"
Write-ColorOutput Green "PodMonitor Operator 镜像构建脚本"
Write-ColorOutput Green "========================================"
Write-Output ""
Write-Output "镜像仓库: $Registry"
Write-Output "命名空间: $Namespace"
Write-Output "镜像标签: $Tag"
Write-Output "完整地址: $Image"
Write-Output ""

# 步骤 1: 构建镜像
Write-ColorOutput Yellow "[1/3] 构建 Docker 镜像..."
docker build -t $Image .
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "错误: 镜像构建失败"
    exit 1
}
Write-ColorOutput Green "✓ 镜像构建成功"
Write-Output ""

# 步骤 2: 登录镜像仓库
if (-not $SkipPush) {
    Write-ColorOutput Yellow "[2/3] 登录镜像仓库..."
    Write-Output "请输入登录信息（或按 Ctrl+C 跳过，稍后手动登录）"
    docker login $Registry
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Yellow "警告: 登录失败，请手动执行: docker login $Registry"
        Write-Output "是否继续推送？(y/N)"
        $response = Read-Host
        if ($response -ne "y" -and $response -ne "Y") {
            Write-ColorOutput Yellow "跳过推送，请稍后手动执行: docker push $Image"
            exit 0
        }
    } else {
        Write-ColorOutput Green "✓ 登录成功"
    }
    Write-Output ""

    # 步骤 3: 推送镜像
    Write-ColorOutput Yellow "[3/3] 推送镜像到仓库..."
    docker push $Image
    if ($LASTEXITCODE -ne 0) {
        Write-ColorOutput Red "错误: 镜像推送失败"
        exit 1
    }
    Write-ColorOutput Green "✓ 镜像推送成功"
} else {
    Write-ColorOutput Yellow "跳过推送（使用 -SkipPush 参数）"
    Write-Output "手动推送命令: docker push $Image"
}

Write-Output ""
Write-ColorOutput Green "========================================"
Write-ColorOutput Green "完成！"
Write-ColorOutput Green "========================================"
Write-Output ""
Write-Output "镜像地址: $Image"
Write-Output ""
Write-Output "下一步:"
Write-Output "1. 验证镜像: docker pull $Image"
Write-Output "2. 使用 Helm 安装: 参考 INSTALL_FROM_HELM.md"
Write-Output ""

