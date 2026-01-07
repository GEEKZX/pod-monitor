# 从 Helm 仓库安装 PodMonitor Operator

本指南介绍如何从已发布的 Helm 仓库安装 PodMonitor Operator。

## 前置要求

- Kubernetes 1.20+ 集群
- Helm 3.0+ 已安装
- kubectl 已配置并连接到集群

## 安装方式

### 方式一：从 GitHub Pages 安装（推荐）

如果你的 Helm Chart 已发布到 GitHub Pages：

```bash
# 1. 添加 Helm 仓库（替换为你的实际 GitHub Pages URL）
helm repo add podmonitor https://your-username.github.io/pod-monitor/charts

# 2. 更新仓库列表
helm repo update

# 3. 查看可用的 Chart 版本
helm search repo podmonitor

# 4. 安装 Operator（需要指定镜像地址）
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller \
  --set image.tag=v1.0.0
```

**注意**：请将 `your-username` 替换为你的 GitHub 用户名，`pod-monitor` 替换为你的仓库名。

### 方式二：从本地 charts 目录安装

如果你有本地的 charts 目录：

```bash
# 1. 添加本地目录作为 Helm 仓库
helm repo add podmonitor-local file:///d/pod-monitor/charts

# 2. 更新仓库
helm repo update

# 3. 安装
helm install podmonitor-operator podmonitor-local/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller \
  --set image.tag=v1.0.0
```

### 方式三：从 OCI Registry 安装

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
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller \
  --set image.tag=v1.0.0
```

### 方式四：直接使用本地 Chart 文件安装

如果你有打包好的 `.tgz` 文件：

```bash
# 直接安装本地 Chart 包
helm install podmonitor-operator ./charts/podmonitor-operator-0.1.0.tgz \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller \
  --set image.tag=v1.0.0
```

## 使用自定义 values 文件安装

推荐使用自定义 values 文件来管理配置：

```bash
# 1. 查看默认 values
helm show values podmonitor/podmonitor-operator > my-values.yaml

# 2. 编辑 my-values.yaml，设置你的配置
# 主要需要修改：
# - image.repository: 你的镜像仓库地址
# - image.tag: 镜像标签
# - imagePullSecrets: 如果需要从私有仓库拉取

# 3. 使用自定义 values 安装
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  -f my-values.yaml
```

### 示例 values.yaml

```yaml
# 镜像配置
image:
  repository: registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller
  tag: v1.0.0
  pullPolicy: IfNotPresent

# 如果使用私有镜像仓库，需要配置 imagePullSecrets
imagePullSecrets:
  - name: acr-secret

# Operator 配置
operator:
  replicaCount: 1
  resources:
    limits:
      cpu: 500m
      memory: 128Mi
    requests:
      cpu: 10m
      memory: 64Mi

# 邮件通知配置（可选）
operator:
  env:
  - name: SMTP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: smtp-credentials
        key: password

# 示例 PodMonitor（可选）
samplePodMonitor:
  create: true
  config:
    namespaces:
      - default
    maxRunDurationSeconds: 3600
    checkIntervalSeconds: 60
    autoCleanup: true
    emailNotification:
      enabled: true
      recipients:
        - ops-team@example.com
      smtpServer: smtp.example.com
      smtpPort: 587
      from: podmonitor@example.com
      useTLS: true
```

## 验证安装

安装完成后，验证 Operator 是否正常运行：

```bash
# 1. 检查 Pod 状态
kubectl get pods -n podmonitor-system

# 应该看到类似输出：
# NAME                                  READY   STATUS    RESTARTS   AGE
# podmonitor-operator-xxxxxxxxxx-xxxxx  1/1     Running   0          30s

# 2. 查看 Operator 日志
kubectl logs -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator -f

# 3. 检查 CRD 是否已安装
kubectl get crd podmonitors.podmonitor.pod-monitor.io

# 4. 查看 Helm Release 状态
helm status podmonitor-operator -n podmonitor-system

# 5. 查看已安装的资源
helm get manifest podmonitor-operator -n podmonitor-system
```

## 配置私有镜像仓库

如果使用私有镜像仓库（如阿里云 ACR），需要先创建镜像拉取密钥：

```bash
# 创建镜像拉取密钥
kubectl create secret docker-registry acr-secret \
  --docker-server=registry.cn-hangzhou.aliyuncs.com \
  --docker-username=your_access_key_id \
  --docker-password=your_access_key_secret \
  -n podmonitor-system

# 然后在安装时指定 imagePullSecrets
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller \
  --set image.tag=v1.0.0 \
  --set imagePullSecrets[0].name=acr-secret
```

## 配置邮件通知

如果需要启用邮件通知功能：

```bash
# 1. 创建 SMTP 密码 Secret
kubectl create secret generic smtp-credentials \
  --from-literal=password='your-smtp-password' \
  -n podmonitor-system

# 2. 在 values.yaml 中配置邮件相关参数（见上面的示例）

# 3. 使用配置好的 values 文件安装
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  -f my-values.yaml
```

## 升级

当有新版本发布时，可以升级现有安装：

```bash
# 1. 更新仓库
helm repo update

# 2. 查看新版本
helm search repo podmonitor

# 3. 升级（使用新镜像标签）
helm upgrade podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --set image.tag=v1.1.0

# 或使用 values 文件
helm upgrade podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  -f my-values.yaml
```

## 卸载

如果需要卸载 Operator：

```bash
# 卸载 Operator（保留 CRD 和 PodMonitor 资源）
helm uninstall podmonitor-operator --namespace podmonitor-system

# 如果需要完全删除（包括 CRD，会删除所有 PodMonitor 资源）
helm uninstall podmonitor-operator --namespace podmonitor-system
kubectl delete crd podmonitors.podmonitor.pod-monitor.io
```

## 故障排查

### 问题 1: 无法添加仓库

```bash
# 检查仓库 URL 是否正确
curl https://your-username.github.io/pod-monitor/charts/index.yaml

# 如果返回 404，检查：
# - GitHub Pages 是否已启用
# - 路径是否正确
# - 等待几分钟让 GitHub 更新
```

### 问题 2: Pod 无法启动

```bash
# 查看 Pod 详细信息
kubectl describe pod -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator

# 查看事件
kubectl get events -n podmonitor-system --sort-by='.lastTimestamp'

# 查看日志
kubectl logs -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator
```

### 问题 3: 镜像拉取失败

```bash
# 检查镜像是否存在
docker pull <your-image>

# 检查 imagePullSecrets
kubectl get secret -n podmonitor-system

# 检查 Secret 内容
kubectl get secret acr-secret -n podmonitor-system -o yaml
```

### 问题 4: RBAC 权限问题

```bash
# 检查 ClusterRole 和 ClusterRoleBinding
kubectl get clusterrole | grep podmonitor
kubectl get clusterrolebinding | grep podmonitor

# 查看详细权限
kubectl describe clusterrole podmonitor-operator
```

## 快速安装命令（一键安装）

如果你已经知道所有配置信息，可以使用以下命令快速安装：

```bash
# 设置变量
export HELM_REPO_URL="https://your-username.github.io/pod-monitor/charts"
export IMAGE_REPO="registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller"
export IMAGE_TAG="v1.0.0"
export NAMESPACE="podmonitor-system"

# 添加仓库并安装
helm repo add podmonitor ${HELM_REPO_URL}
helm repo update
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --set image.repository=${IMAGE_REPO} \
  --set image.tag=${IMAGE_TAG}

# 验证
kubectl get pods -n ${NAMESPACE}
```

## 更多信息

- [Helm 部署指南](./HELM_DEPLOY.md)
- [项目 README](./README.md)
- [阿里云部署指南](./DEPLOY_ALIYUN.md)

