# PodMonitor Operator Helm Chart

这个 Helm Chart 用于在 Kubernetes 集群中部署 PodMonitor Operator。

## 前置要求

- Kubernetes 1.20+
- Helm 3.0+
- kubectl 已配置并连接到集群

## 安装

### 从本地 Chart 安装

```bash
# 1. 添加必要的配置（修改镜像地址等）
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller \
  --set image.tag=v1.0.0
```

### 使用自定义 values 文件

```bash
# 1. 复制并编辑 values 文件
cp helm/podmonitor-operator/values.yaml my-values.yaml

# 2. 编辑 my-values.yaml，设置你的配置

# 3. 安装
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  -f my-values.yaml
```

## 配置

### 主要配置项

| 参数 | 描述 | 默认值 |
|------|------|--------|
| `image.repository` | 镜像仓库地址 | `podmonitor-controller` |
| `image.tag` | 镜像标签 | `latest` |
| `image.pullPolicy` | 镜像拉取策略 | `IfNotPresent` |
| `operator.replicaCount` | Operator 副本数 | `1` |
| `operator.leaderElection` | 是否启用 leader election | `true` |
| `operator.resources` | 资源限制 | 见 values.yaml |
| `crd.install` | 是否安装 CRD | `true` |
| `rbac.create` | 是否创建 RBAC | `true` |
| `samplePodMonitor.create` | 是否创建示例 PodMonitor | `false` |

### 邮件通知配置

在 `values.yaml` 中配置邮件通知：

```yaml
operator:
  env:
  - name: SMTP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: smtp-credentials
        key: password

samplePodMonitor:
  create: true
  config:
    emailNotification:
      enabled: true
      recipients:
        - ops-team@example.com
      smtpServer: smtp.example.com
      smtpPort: 587
      from: podmonitor@example.com
      useTLS: true
```

### 使用 Secret 存储 SMTP 密码

```bash
# 创建 Secret
kubectl create secret generic smtp-credentials \
  --from-literal=password='your-password' \
  -n podmonitor-system

# 在 values.yaml 中引用
operator:
  env:
  - name: SMTP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: smtp-credentials
        key: password
```

## 升级

```bash
# 升级到新版本
helm upgrade podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --set image.tag=v1.1.0
```

## 卸载

```bash
# 卸载 Operator（保留 CRD 和 PodMonitor 资源）
helm uninstall podmonitor-operator --namespace podmonitor-system

# 如果需要删除 CRD（会删除所有 PodMonitor 资源）
kubectl delete crd podmonitors.podmonitor.pod-monitor.io
```

## 验证安装

```bash
# 检查 Pod 状态
kubectl get pods -n podmonitor-system

# 查看 Operator 日志
kubectl logs -n podmonitor-system deployment/podmonitor-operator -f

# 检查 CRD
kubectl get crd podmonitors.podmonitor.pod-monitor.io

# 查看 PodMonitor 资源
kubectl get podmonitor -A
```

## 示例：阿里云 ACK 部署

```bash
# 设置镜像地址
export IMAGE="registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller:v1.0.0"

# 安装
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller \
  --set image.tag=v1.0.0 \
  --set imagePullSecrets[0].name=acr-secret
```

## 故障排查

### Pod 无法启动

```bash
# 查看 Pod 状态
kubectl describe pod -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator

# 查看日志
kubectl logs -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator
```

### 镜像拉取失败

```bash
# 检查镜像是否存在
docker pull <your-image>

# 检查 imagePullSecrets 配置
kubectl get secret -n podmonitor-system
```

### RBAC 权限问题

```bash
# 检查 ClusterRole 和 ClusterRoleBinding
kubectl get clusterrole | grep podmonitor
kubectl get clusterrolebinding | grep podmonitor
```

## 更多信息

- [项目 README](../README.md)
- [部署指南](../DEPLOY_ALIYUN.md)
