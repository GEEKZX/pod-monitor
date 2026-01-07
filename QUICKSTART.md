# 快速开始指南

本指南介绍如何在本地开发环境中运行和测试 PodMonitor Operator。

## 前置要求

- Go 1.20+
- Kubernetes 1.20+ 集群
- kubectl 已配置并连接到集群
- Docker（用于构建镜像）

## 本地开发

### 1. 安装依赖

```bash
go mod download
```

### 2. 生成代码

```bash
make generate
```

### 3. 安装 CRD

```bash
make install
```

### 4. 本地运行 Operator

```bash
# 确保已配置 kubectl 连接到你的 Kubernetes 集群
kubectl cluster-info

# 运行 Operator（需要集群访问权限）
make run
```

## 部署到集群

### 1. 安装 CRD

```bash
kubectl apply -f config/crd/bases/podmonitor.podmonitor.pod-monitor.io_podmonitors.yaml
```

### 2. 部署 Operator

```bash
# 创建命名空间
kubectl create namespace podmonitor-system

# 部署 RBAC
kubectl apply -f config/rbac/

# 构建并推送镜像
docker build -t ghcr.io/geekzx/podmonitor-controller:latest .
docker push ghcr.io/geekzx/podmonitor-controller:latest

# 更新部署文件中的镜像
sed -i 's|podmonitor-controller:latest|ghcr.io/geekzx/podmonitor-controller:latest|g' config/manager/manager.yaml

# 部署 Operator
kubectl apply -f config/manager/manager.yaml
```

### 3. 创建监控实例

```bash
kubectl apply -f config/samples/podmonitor_v1_podmonitor.yaml
```

### 4. 查看监控状态

```bash
kubectl get podmonitor
kubectl get podmonitor podmonitor-sample -o yaml
kubectl logs -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator -f
```

## 配置示例

更多配置示例请参考 [README.md](./README.md) 中的配置说明部分。

## 故障排查

### 查看 Operator 日志

```bash
kubectl logs -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator -f
```

### 检查 RBAC 权限

```bash
kubectl auth can-i get pods --as=system:serviceaccount:podmonitor-system:podmonitor-operator
kubectl auth can-i delete pods --as=system:serviceaccount:podmonitor-system:podmonitor-operator
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
kubectl delete -f config/crd/bases/podmonitor.podmonitor.pod-monitor.io_podmonitors.yaml
```

## 相关文档

- [项目 README](./README.md)
- [Helm 部署指南](./HELM_DEPLOY.md)
- [构建和发布镜像](./BUILD_AND_PUBLISH.md)
