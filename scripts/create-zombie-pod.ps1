# 创建示例僵尸 Pod 脚本 (Windows PowerShell)
# 使用方法: .\scripts\create-zombie-pod.ps1 [namespace] [pod-name]

param(
    [string]$Namespace = "default",
    [string]$PodName = "zombie-pod-test-$(Get-Date -Format 'yyyyMMddHHmmss')"
)

Write-Host "创建测试用的僵尸 Pod..." -ForegroundColor Yellow
Write-Host "命名空间: $Namespace"
Write-Host "Pod 名称: $PodName"
Write-Host ""

# 创建一个会长时间运行的 Pod
kubectl run $PodName `
  --image=busybox:latest `
  --namespace=$Namespace `
  --restart=Never `
  -- /bin/sh -c "echo '这是一个测试僵尸 Pod，会持续运行'; while true; do sleep 3600; done"

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Pod 已创建: $PodName" -ForegroundColor Green
    Write-Host ""
    Write-Host "等待 Pod 启动..." -ForegroundColor Yellow
    kubectl wait --for=condition=Ready pod/$PodName -n $Namespace --timeout=60s 2>$null
    
    Write-Host ""
    Write-Host "Pod 信息:" -ForegroundColor Cyan
    kubectl get pod $PodName -n $Namespace -o wide
    
    Write-Host ""
    Write-Host "提示:" -ForegroundColor Yellow
    Write-Host "1. 如果 PodMonitor 的 maxRunDurationSeconds 设置为 3600 秒（1小时），这个 Pod 运行超过 1 小时后会被检测为僵尸 Pod"
    Write-Host "2. 如果想更快看到效果，可以调整 PodMonitor 的 maxRunDurationSeconds 为更短的时间（如 300 秒）"
    Write-Host "3. 查看 Pod 状态: kubectl get pod $PodName -n $Namespace"
    Write-Host "4. 删除 Pod: kubectl delete pod $PodName -n $Namespace"
} else {
    Write-Host "Pod 创建失败！" -ForegroundColor Red
    exit 1
}

