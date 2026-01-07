# 代码生成脚本
# 使用方法: .\scripts\generate-code.ps1

Write-Host "正在安装 controller-gen..." -ForegroundColor Yellow

# 设置 GOPROXY（如果需要）
$env:GOPROXY = "https://goproxy.cn,direct"

# 安装 controller-gen
go install sigs.k8s.io/controller-tools/cmd/controller-gen@v0.13.0

if ($LASTEXITCODE -ne 0) {
    Write-Host "安装 controller-gen 失败！" -ForegroundColor Red
    exit 1
}

Write-Host "controller-gen 安装成功" -ForegroundColor Green

# 查找 controller-gen
$gopath = go env GOPATH
$controllerGen = Join-Path $gopath "bin\controller-gen.exe"

if (-not (Test-Path $controllerGen)) {
    Write-Host "找不到 controller-gen，尝试使用 PATH 中的版本" -ForegroundColor Yellow
    $controllerGen = "controller-gen"
}

Write-Host "正在生成代码..." -ForegroundColor Yellow
Write-Host "使用: $controllerGen object paths=`"./...`""

# 运行代码生成
& $controllerGen object paths="./..."

if ($LASTEXITCODE -eq 0) {
    Write-Host "代码生成成功！" -ForegroundColor Green
    Write-Host "生成的文件:" -ForegroundColor Cyan
    Get-ChildItem -Path "api\v1" -Filter "zz_generated*" | ForEach-Object { Write-Host "  - $($_.FullName)" }
} else {
    Write-Host "Code generation failed!" -ForegroundColor Red
    exit 1
}

