# Helm 部署指南

本指南介绍如何使用 Helm Chart 部署 PodMonitor Operator。

## 前置要求

- Kubernetes 1.20+ 集群
- Helm 3.0+ 已安装（Windows 用户参考 [INSTALL_HELM_WINDOWS.md](./INSTALL_HELM_WINDOWS.md)）
- kubectl 已配置并连接到集群

## 快速开始

### 从 Helm 仓库安装（推荐）

```bash
# 1. 添加 Helm 仓库
helm repo add podmonitor https://geekzx.github.io/pod-monitor/charts
helm repo update

# 2. 查看可用的 Chart 版本
helm search repo podmonitor

# 3. 安装 Operator
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=ghcr.io/geekzx/podmonitor-controller \
  --set image.tag=v1.0.0 \
  --set image.pullPolicy=Always
```

### 从本地 Chart 安装

```bash
# 安装到指定命名空间
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=ghcr.io/geekzx/podmonitor-controller \
  --set image.tag=v1.0.0 \
  --set image.pullPolicy=Always
```

### 从 OCI Registry 安装

如果发布到 OCI Registry（如阿里云 ACR）：

```bash
# 1. 登录 OCI Registry
helm registry login registry.cn-hangzhou.aliyuncs.com

# 2. 添加 OCI 仓库
helm repo add podmonitor oci://registry.cn-hangzhou.aliyuncs.com/your-namespace/charts

# 3. 更新仓库
helm repo update

# 4. 安装
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=your-registry/podmonitor-controller \
  --set image.tag=v1.0.0
```

### 验证安装

```bash
kubectl get pods -n podmonitor-system
kubectl get crd podmonitors.podmonitor.pod-monitor.io
kubectl logs -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator -f
```

## 配置说明

### 基本配置

使用 `--set` 参数或自定义 values 文件：

```bash
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=ghcr.io/geekzx/podmonitor-controller \
  --set image.tag=v1.0.0 \
  --set image.pullPolicy=Always \
  --set operator.replicaCount=1
```

### 使用自定义 values 文件

```bash
# 1. 查看默认 values
helm show values podmonitor/podmonitor-operator > my-values.yaml

# 2. 编辑 my-values.yaml，设置你的配置
# 主要需要修改：
# - image.repository
# - image.tag
# - image.pullPolicy

# 3. 安装
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  -f my-values.yaml
```

### 邮件通知配置

#### 1. 创建 SMTP Secret

```bash
kubectl create secret generic smtp-credentials \
  --from-literal=password='your-smtp-password' \
  -n podmonitor-system
```

#### 2. 在 values.yaml 中配置环境变量

```yaml
operator:
  env:
  - name: SMTP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: smtp-credentials
        key: password
```

### 使用私有镜像仓库

```bash
# 1. 创建镜像拉取密钥
kubectl create secret docker-registry acr-secret \
  --docker-server=your-registry.com \
  --docker-username=your-username \
  --docker-password=your-password \
  -n podmonitor-system

# 2. 在 values.yaml 中配置
imagePullSecrets:
  - name: acr-secret
```

## 创建监控实例

```bash
kubectl apply -f config/samples/podmonitor_v1_podmonitor.yaml
kubectl get podmonitor -A
```

⚠️ **重要提示**：示例配置中 `autoCleanup` 默认为 `false`。如果启用自动清理（设置为 `true`），Operator 会自动删除超过最大运行时长的 Pod，这可能导致：
- 数据丢失
- 服务中断
- 无法恢复的 Pod 删除

**建议**：
- 在生产环境使用前，先在测试环境验证配置
- 使用 `labelSelector` 精确控制要监控的 Pod
- 合理设置 `maxRunDurationSeconds` 避免误删正常 Pod
- 启用邮件通知以便及时了解清理情况

## 升级

```bash
# 升级到新版本
helm upgrade podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --set image.tag=v1.0.1 \
  --set image.pullPolicy=Always

# 删除 Pod 强制拉取新镜像
kubectl delete pod -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator
```

## 卸载

```bash
# 卸载 Operator（保留 CRD 和 PodMonitor 资源）
helm uninstall podmonitor-operator --namespace podmonitor-system

# 完全删除（包括 CRD）
helm uninstall podmonitor-operator --namespace podmonitor-system
kubectl delete crd podmonitors.podmonitor.pod-monitor.io
```

## 常见问题

### Chart 验证失败

```bash
# 验证 Chart
helm lint ./helm/podmonitor-operator

# 检查模板渲染
helm template podmonitor-operator ./helm/podmonitor-operator
```

### 镜像拉取失败

```bash
# 检查 imagePullSecrets
kubectl get secret -n podmonitor-system

# 检查 Pod 事件
kubectl describe pod -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator

# 检查镜像是否存在
docker pull ghcr.io/geekzx/podmonitor-controller:v1.0.0
```

### 权限问题

```bash
# 检查 RBAC
kubectl get clusterrole | grep podmonitor
kubectl get clusterrolebinding | grep podmonitor
```

### 仓库添加失败

```bash
# 检查网络连接
curl https://geekzx.github.io/pod-monitor/charts/index.yaml

# 手动添加仓库
helm repo add podmonitor https://geekzx.github.io/pod-monitor/charts --force-update
```

## 相关文档

- [项目 README](./README.md)
- [发布 Helm Chart](./PUBLISH_HELM.md)
- [构建和发布镜像](./BUILD_AND_PUBLISH.md)
