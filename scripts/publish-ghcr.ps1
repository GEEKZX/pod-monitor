# GitHub Container Registry 镜像发布脚本 (Windows PowerShell)
# 使用方法: .\scripts\publish-ghcr.ps1 -Username "geekzx" -Tag "v1.0.0" [-Token "your_pat"]

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    [string]$Tag = "v1.0.0",
    [string]$Token = ""
)

# 颜色输出函数
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

$ImageName = "podmonitor-controller"
$Image = "ghcr.io/${Username}/${ImageName}:${Tag}"

Write-Output ""
Write-ColorOutput Green "========================================"
Write-ColorOutput Green "发布镜像到 GitHub Container Registry"
Write-ColorOutput Green "========================================"
Write-Output ""
Write-Output "GitHub 用户名: $Username"
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

# 步骤 2: 登录 GHCR
Write-ColorOutput Yellow "[2/3] 登录 GitHub Container Registry..."
if ($Token) {
    echo $Token | docker login ghcr.io -u $Username --password-stdin
} else {
    Write-ColorOutput Yellow "提示: 如果没有提供 Token，将使用交互式登录"
    docker login ghcr.io
}
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "错误: 登录失败"
    exit 1
}
Write-ColorOutput Green "✓ 登录成功"
Write-Output ""

# 步骤 3: 推送镜像
Write-ColorOutput Yellow "[3/3] 推送镜像到 GHCR..."
docker push $Image
if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput Red "错误: 镜像推送失败"
    exit 1
}
Write-ColorOutput Green "✓ 镜像推送成功"
Write-Output ""

# 完成提示
Write-ColorOutput Green "========================================"
Write-ColorOutput Green "发布完成！"
Write-ColorOutput Green "========================================"
Write-Output ""
Write-ColorOutput Cyan "镜像地址: https://github.com/users/$Username/packages/container/$ImageName"
Write-ColorOutput Yellow "重要提示: 记得在 GitHub 上将镜像设置为公开！"
Write-Output ""
Write-ColorOutput Yellow "设置公开的步骤:"
Write-Output "1. 访问: https://github.com/users/$Username/packages/container/$ImageName"
Write-Output "2. 点击右侧的 'Package settings' (齿轮图标)"
Write-Output "3. 滚动到底部 'Danger Zone'"
Write-Output "4. 点击 'Change visibility' -> 选择 'Public'"
Write-Output ""

