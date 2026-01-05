# 快速开始指南

## 本地开发环境设置

### 1. 安装依赖

```bash
go mod download
```

### 2. 生成代码（如果需要）

```bash
make generate
```

### 3. 本地运行 Operator

```bash
# 确保已配置 kubectl 连接到你的 Kubernetes 集群
kubectl cluster-info

# 运行 Operator（需要集群访问权限）
make run
```

## 部署到集群

### 1. 安装 CRD

```bash
kubectl apply -f config/crd/bases/podmonitor.pod-monitor.io_podmonitors.yaml
```

### 2. 部署 Operator

```bash
# 创建命名空间
kubectl create namespace podmonitor-system

# 部署 RBAC
kubectl apply -f config/rbac/

# 构建并推送镜像（根据你的镜像仓库修改）
docker build -t your-registry/podmonitor-controller:latest .
docker push your-registry/podmonitor-controller:latest

# 更新部署文件中的镜像
sed -i 's|podmonitor-controller:latest|your-registry/podmonitor-controller:latest|g' config/manager/manager.yaml

# 部署 Operator
kubectl apply -f config/manager/manager.yaml
```

### 3. 创建监控实例

```bash
kubectl apply -f config/samples/podmonitor_v1_podmonitor.yaml
```

### 4. 查看监控状态

```bash
# 查看 PodMonitor 资源
kubectl get podmonitor

# 查看详细信息
kubectl describe podmonitor podmonitor-sample

# 查看状态
kubectl get podmonitor podmonitor-sample -o yaml
```

## 配置示例

### 监控所有命名空间，自动清理超过 2 小时的任务

```yaml
apiVersion: podmonitor.pod-monitor.io/v1
kind: PodMonitor
metadata:
  name: global-monitor
spec:
  namespaces: []  # 空列表表示监控所有命名空间
  maxRunDurationSeconds: 7200  # 2小时
  checkIntervalSeconds: 120    # 每2分钟检查一次
  autoCleanup: true
  gracePeriodSeconds: 600      # 10分钟宽限期
```

### 只监控特定标签的任务

```yaml
apiVersion: podmonitor.pod-monitor.io/v1
kind: PodMonitor
metadata:
  name: batch-pod-monitor
spec:
  namespaces:
    - production
    - staging
  labelSelector:
    job-type: batch
    environment: production
  maxRunDurationSeconds: 1800  # 30分钟
  checkIntervalSeconds: 60
  autoCleanup: true
  gracePeriodSeconds: 300
```

## 故障排查

### 查看 Operator 日志

```bash
kubectl logs -n podmonitor-system deployment/podmonitor-controller-manager
```

### 检查 RBAC 权限

```bash
kubectl auth can-i get pods --as=system:serviceaccount:podmonitor-system:podmonitor-controller-manager
kubectl auth can-i delete pods --as=system:serviceaccount:podmonitor-system:podmonitor-controller-manager
```

### 验证 CRD 已安装

```bash
kubectl get crd podmonitors.podmonitor.pod-monitor.io
```

## 卸载

```bash
# 删除监控实例
kubectl delete podmonitor --all

# 卸载 Operator
kubectl delete -f config/manager/manager.yaml
kubectl delete -f config/rbac/
kubectl delete namespace podmonitor-system

# 删除 CRD
kubectl delete -f config/crd/bases/podmonitor.pod-monitor.io_podmonitors.yaml
```

