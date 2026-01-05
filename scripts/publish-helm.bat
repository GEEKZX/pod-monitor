@echo off
REM Helm Chart 发布脚本 (Windows)
REM 使用方法: scripts\publish-helm.bat [version]

setlocal enabledelayedexpansion

echo ========================================
echo PodMonitor Helm Chart 发布脚本
echo ========================================
echo.

REM 检查 Helm 是否安装
where helm >nul 2>&1
if %errorlevel% neq 0 (
    echo 错误: Helm 未安装
    echo 请先安装 Helm: https://helm.sh/docs/intro/install/
    exit /b 1
)

REM 检查是否在项目根目录
if not exist "helm\podmonitor-operator\Chart.yaml" (
    echo 错误: 请在项目根目录执行此脚本
    exit /b 1
)

REM 获取版本号
set VERSION=%1
if "%VERSION%"=="" (
    REM 从 Chart.yaml 读取版本
    for /f "tokens=2" %%a in ('findstr /C:"version:" helm\podmonitor-operator\Chart.yaml') do set VERSION=%%a
    echo 使用 Chart.yaml 中的版本: %VERSION%
) else (
    echo 使用指定版本: %VERSION%
    REM 更新 Chart.yaml 中的版本（需要 sed 或手动编辑）
    echo 提示: 请手动更新 helm\podmonitor-operator\Chart.yaml 中的版本为 %VERSION%
)

REM 步骤 1: 打包 Chart
echo.
echo [1/5] 打包 Helm Chart...
helm package helm\podmonitor-operator
if %errorlevel% neq 0 (
    echo 错误: 打包失败
    exit /b 1
)
set CHART_FILE=podmonitor-operator-%VERSION%.tgz
echo ✓ Chart 打包成功: %CHART_FILE%

REM 步骤 2: 创建 charts 目录
echo.
echo [2/5] 准备 charts 目录...
if not exist "charts" mkdir charts

REM 步骤 3: 移动文件
echo.
echo [3/5] 移动 Chart 文件...
move /Y %CHART_FILE% charts\ >nul
echo ✓ 文件已移动到 charts\ 目录

REM 步骤 4: 生成/更新索引
echo.
echo [4/5] 生成 Helm Repository 索引...
if exist "charts\index.yaml" (
    echo 合并到现有索引...
    helm repo index charts\ --merge charts\index.yaml
) else (
    echo 创建新索引...
    helm repo index charts\
)
echo ✓ 索引文件已生成: charts\index.yaml

REM 步骤 5: 显示状态
echo.
echo [5/5] 完成！
echo.
echo ========================================
echo 打包完成！
echo ========================================
echo.
echo 下一步操作:
echo.
echo 1. 检查生成的文件:
echo    dir charts
echo.
echo 2. 添加并提交到 Git:
echo    git add charts\ helm\podmonitor-operator\Chart.yaml
echo    git commit -m "Release Helm chart v%VERSION%"
echo.
echo 3. 推送到 GitHub:
echo    git push
echo.
echo 4. 确保 GitHub Pages 已启用（Settings -^> Pages）
echo.
echo 5. 验证发布:
echo    helm repo add podmonitor https://your-username.github.io/your-repo/charts
echo    helm repo update
echo    helm search repo podmonitor
echo.

endlocal

