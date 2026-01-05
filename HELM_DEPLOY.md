# Helm 部署指南

本指南介绍如何使用 Helm Chart 部署 PodMonitor Operator。

## 快速开始

### 1. 准备镜像

首先需要构建并推送镜像到你的镜像仓库：

```bash
# 设置镜像地址（以阿里云 ACR 为例）
export IMAGE_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
export IMAGE_NAMESPACE="your-namespace"
export IMAGE_NAME="podmonitor-controller"
export IMAGE_TAG="v1.0.0"
export IMAGE="${IMAGE_REGISTRY}/${IMAGE_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"

# 构建镜像
docker build -t ${IMAGE} .

# 登录并推送
docker login ${IMAGE_REGISTRY}
docker push ${IMAGE}
```

### 2. 安装 Helm Chart

#### 方式一：直接安装（推荐）

```bash
# 安装到指定命名空间
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=${IMAGE_REGISTRY}/${IMAGE_NAMESPACE}/${IMAGE_NAME} \
  --set image.tag=${IMAGE_TAG}
```

#### 方式二：使用自定义 values 文件

```bash
# 1. 复制 values 文件
cp helm/podmonitor-operator/values.yaml my-values.yaml

# 2. 编辑 my-values.yaml，设置镜像地址等配置
# image:
#   repository: registry.cn-hangzhou.aliyuncs.com/your-namespace/podmonitor-controller
#   tag: v1.0.0

# 3. 安装
helm install podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  -f my-values.yaml
```

### 3. 验证安装

```bash
# 检查 Pod 状态
kubectl get pods -n podmonitor-system

# 查看日志
kubectl logs -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator -f

# 检查 CRD
kubectl get crd podmonitors.podmonitor.pod-monitor.io
```

## 配置说明

### 基本配置

编辑 `values.yaml` 或使用 `--set` 参数：

```bash
helm install podmonitor-operator ./helm/podmonitor-operator \
  --set image.repository=your-registry/podmonitor-controller \
  --set image.tag=v1.0.0 \
  --set operator.replicaCount=1
```

### 邮件通知配置

#### 1. 创建 SMTP Secret

```bash
kubectl create secret generic smtp-credentials \
  --from-literal=password='your-smtp-password' \
  -n podmonitor-system
```

#### 2. 配置环境变量

在 `values.yaml` 中：

```yaml
operator:
  env:
  - name: SMTP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: smtp-credentials
        key: password
```

#### 3. 创建示例 PodMonitor（带邮件通知）

```yaml
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

然后安装：

```bash
helm install podmonitor-operator ./helm/podmonitor-operator \
  -f my-values.yaml
```

### 使用私有镜像仓库

如果使用私有镜像仓库，需要配置 `imagePullSecrets`：

```bash
# 1. 创建镜像拉取密钥
kubectl create secret docker-registry acr-secret \
  --docker-server=registry.cn-hangzhou.aliyuncs.com \
  --docker-username=your_access_key_id \
  --docker-password=your_access_key_secret \
  -n podmonitor-system

# 2. 在 values.yaml 中配置
imagePullSecrets:
  - name: acr-secret

# 3. 安装
helm install podmonitor-operator ./helm/podmonitor-operator \
  -f my-values.yaml
```

## 升级

```bash
# 升级到新版本
helm upgrade podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  --set image.tag=v1.1.0

# 或使用 values 文件
helm upgrade podmonitor-operator ./helm/podmonitor-operator \
  --namespace podmonitor-system \
  -f my-values.yaml
```

## 卸载

```bash
# 卸载 Operator（保留 CRD 和 PodMonitor 资源）
helm uninstall podmonitor-operator --namespace podmonitor-system

# 如果需要完全删除（包括 CRD）
helm uninstall podmonitor-operator --namespace podmonitor-system
kubectl delete crd podmonitors.podmonitor.pod-monitor.io
```

## 发布到 Helm Repository

如果你想将 Chart 发布到 Helm 仓库：

### 1. 打包 Chart

```bash
# 打包
helm package ./helm/podmonitor-operator

# 会生成 podmonitor-operator-0.1.0.tgz
```

### 2. 创建 Helm Repository

#### 使用 GitHub Pages

```bash
# 1. 创建 charts 目录
mkdir charts

# 2. 移动打包文件
mv podmonitor-operator-0.1.0.tgz charts/

# 3. 生成索引
helm repo index charts/

# 4. 提交到 GitHub
git add charts/
git commit -m "Add Helm chart"
git push
```

#### 使用 OCI Registry（如阿里云 ACR）

```bash
# 1. 登录 OCI Registry
helm registry login registry.cn-hangzhou.aliyuncs.com

# 2. 推送 Chart
helm push podmonitor-operator-0.1.0.tgz oci://registry.cn-hangzhou.aliyuncs.com/your-namespace/charts
```

### 3. 添加 Repository

```bash
# 从 GitHub Pages
helm repo add podmonitor https://your-username.github.io/podmonitor-operator/charts
helm repo update

# 从 OCI Registry
helm repo add podmonitor oci://registry.cn-hangzhou.aliyuncs.com/your-namespace/charts
```

### 4. 从 Repository 安装

```bash
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace
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
```

### 权限问题

```bash
# 检查 RBAC
kubectl get clusterrole | grep podmonitor
kubectl get clusterrolebinding | grep podmonitor
```

## 更多信息

- [Helm Chart README](./helm/podmonitor-operator/README.md)
- [项目 README](./README.md)
- [阿里云部署指南](./DEPLOY_ALIYUN.md)

