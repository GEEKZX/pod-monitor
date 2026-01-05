# 阿里云 Kubernetes 集群部署指南

本指南将帮助你将 PodMonitor Operator 部署到阿里云 ACK（容器服务 Kubernetes）集群。

## 前置要求

1. **已安装并配置的工具**：
   - `kubectl` - 已配置连接到你的阿里云集群
   - `docker` 或 `podman` - 用于构建镜像
   - `make` - 用于执行构建命令

2. **阿里云资源**：
   - ACK 集群已创建并运行
   - 容器镜像服务（ACR）已开通（用于存储镜像）
   - 集群访问凭证已配置

## 部署步骤

### 步骤 1: 验证集群连接

```bash
# 验证 kubectl 已连接到正确的集群
kubectl cluster-info
kubectl get nodes
```

### 步骤 2: 准备镜像仓库

#### 2.1 登录阿里云容器镜像服务

```bash
# 设置你的 ACR 地址（根据你的地域选择）
export ACR_REGISTRY="registry.cn-hangzhou.aliyuncs.com"  # 杭州地域示例
# 或者使用其他地域：
# export ACR_REGISTRY="registry.cn-beijing.aliyuncs.com"  # 北京
# export ACR_REGISTRY="registry.cn-shanghai.aliyuncs.com"  # 上海

# 设置你的命名空间和镜像名称
export ACR_NAMESPACE="your-namespace"  # 替换为你的 ACR 命名空间
export IMAGE_NAME="podmonitor-controller"
export IMAGE_TAG="v1.0.0"

# 完整的镜像地址
export IMAGE="${ACR_REGISTRY}/${ACR_NAMESPACE}/${IMAGE_NAME}:${IMAGE_TAG}"

# 登录 ACR（需要输入阿里云账号密码）
docker login ${ACR_REGISTRY}
```

#### 2.2 或者使用 RAM 子账号 AccessKey 登录

```bash
# 使用 AccessKey 登录（更安全，推荐用于 CI/CD）
docker login --username=your_access_key_id --password=your_access_key_secret ${ACR_REGISTRY}
```

### 步骤 3: 构建和推送镜像

#### 3.1 构建 Docker 镜像

```bash
# 构建镜像
make docker-build IMG=${IMAGE}

# 或者直接使用 docker 命令
docker build -t ${IMAGE} .
```

#### 3.2 推送镜像到 ACR

```bash
# 推送镜像
docker push ${IMAGE}

# 验证镜像已推送
docker pull ${IMAGE}
```

### 步骤 4: 安装 CRD

```bash
# 安装自定义资源定义
kubectl apply -f config/crd/bases/podmonitor.pod-monitor.io_podmonitors.yaml

# 验证 CRD 已安装
kubectl get crd podmonitors.podmonitor.pod-monitor.io
```

### 步骤 5: 部署 RBAC

```bash
# 创建命名空间
kubectl create namespace podmonitor-system

# 部署 ServiceAccount 和 RBAC
kubectl apply -f config/rbac/service_account.yaml
kubectl apply -f config/rbac/role.yaml
kubectl apply -f config/rbac/role_binding.yaml

# 验证 RBAC
kubectl get serviceaccount -n podmonitor-system
kubectl get clusterrole podmonitor-manager-role
kubectl get clusterrolebinding podmonitor-manager-rolebinding
```

### 步骤 6: 部署 Operator

#### 6.1 更新部署文件中的镜像地址

```bash
# 编辑部署文件，更新镜像地址
# 方法 1: 使用 sed 命令（Linux/Mac）
sed -i "s|podmonitor-controller:latest|${IMAGE}|g" config/manager/manager.yaml

# 方法 2: 手动编辑 config/manager/manager.yaml
# 将 image: podmonitor-controller:latest 改为 image: ${IMAGE}
```

#### 6.2 部署 Operator

```bash
# 部署 Operator
kubectl apply -f config/manager/manager.yaml

# 验证部署
kubectl get deployment -n podmonitor-system
kubectl get pods -n podmonitor-system

# 查看 Operator 日志
kubectl logs -n podmonitor-system deployment/podmonitor-controller-manager -f
```

### 步骤 7: 配置 SMTP（可选，如果使用邮件通知）

#### 7.1 创建 SMTP 密码 Secret

```bash
# 创建 Secret 存储 SMTP 密码
kubectl create secret generic smtp-credentials \
  --from-literal=password='your-smtp-password' \
  -n podmonitor-system

# 验证 Secret
kubectl get secret smtp-credentials -n podmonitor-system
```

#### 7.2 更新 Deployment 以使用 Secret

编辑 `config/manager/manager.yaml`，在 containers 部分添加环境变量：

```yaml
containers:
- name: manager
  # ... 其他配置 ...
  env:
  - name: SMTP_PASSWORD
    valueFrom:
      secretKeyRef:
        name: smtp-credentials
        key: password
```

然后重新应用：

```bash
kubectl apply -f config/manager/manager.yaml
```

### 步骤 8: 创建监控实例

#### 8.1 创建基础监控配置

```bash
# 使用示例配置创建监控实例
kubectl apply -f config/samples/podmonitor_v1_podmonitor.yaml

# 或者创建自定义配置
cat <<EOF | kubectl apply -f -
apiVersion: podmonitor.pod-monitor.io/v1
kind: PodMonitor
metadata:
  name: podmonitor-production
  namespace: default
spec:
  namespaces:
    - default
    - production
  maxRunDurationSeconds: 3600  # 1小时
  checkIntervalSeconds: 60
  autoCleanup: true
  gracePeriodSeconds: 300
  emailNotification:
    enabled: true
    recipients:
      - ops-team@yourcompany.com
    smtpServer: smtp.aliyun.com
    smtpPort: 465
    from: podmonitor@yourcompany.com
    useTLS: true
    # 密码从环境变量 SMTP_PASSWORD 读取
EOF
```

#### 8.2 验证监控实例

```bash
# 查看监控实例
kubectl get podmonitor

# 查看详细信息
kubectl describe podmonitor podmonitor-sample

# 查看状态
kubectl get podmonitor podmonitor-sample -o yaml
```

## 验证部署

### 检查所有组件

```bash
# 检查 CRD
kubectl get crd | grep podmonitor

# 检查 Operator Pod
kubectl get pods -n podmonitor-system

# 检查 Operator 日志（应该没有错误）
kubectl logs -n podmonitor-system deployment/podmonitor-controller-manager --tail=50

# 检查监控实例状态
kubectl get podmonitor -A
```

### 测试监控功能

```bash
# 创建一个测试任务（运行时间较长，用于测试僵尸任务检测）
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: test-long-running-job
  namespace: default
spec:
  template:
    spec:
      containers:
      - name: sleep
        image: busybox
        command: ["sleep", "7200"]  # 运行 2 小时
      restartPolicy: Never
EOF

# 等待一段时间后，检查是否被检测为僵尸任务
kubectl get podmonitor podmonitor-sample -o yaml
```

## 常见问题排查

### 1. 镜像拉取失败

```bash
# 检查镜像是否存在
docker pull ${IMAGE}

# 检查集群节点是否能访问 ACR
# 确保 ACR 已配置为集群的镜像仓库
```

### 2. Operator Pod 无法启动

```bash
# 查看 Pod 状态
kubectl describe pod -n podmonitor-system

# 查看日志
kubectl logs -n podmonitor-system deployment/podmonitor-controller-manager
```

### 3. 权限问题

```bash
# 检查 RBAC 配置
kubectl auth can-i get jobs --as=system:serviceaccount:podmonitor-system:podmonitor-controller-manager
kubectl auth can-i delete jobs --as=system:serviceaccount:podmonitor-system:podmonitor-controller-manager
```

### 4. 邮件发送失败

```bash
# 检查 SMTP 配置
kubectl get podmonitor podmonitor-sample -o yaml | grep -A 20 emailNotification

# 检查环境变量
kubectl exec -n podmonitor-system deployment/podmonitor-controller-manager -- env | grep SMTP

# 查看日志中的错误信息
kubectl logs -n podmonitor-system deployment/podmonitor-controller-manager | grep -i email
```

## 阿里云 ACK 特定配置

### 使用阿里云内网镜像加速

如果你的集群和 ACR 在同一地域，可以使用内网地址加速：

```bash
# 获取内网地址（在 ACR 控制台查看）
export ACR_REGISTRY="registry-vpc.cn-hangzhou.aliyuncs.com"  # VPC 内网地址
```

### 配置镜像拉取密钥（如果需要）

```bash
# 如果使用私有镜像仓库，创建镜像拉取密钥
kubectl create secret docker-registry acr-secret \
  --docker-server=${ACR_REGISTRY} \
  --docker-username=your_access_key_id \
  --docker-password=your_access_key_secret \
  -n podmonitor-system

# 在 Deployment 中添加 imagePullSecrets
# 编辑 config/manager/manager.yaml，添加：
# imagePullSecrets:
# - name: acr-secret
```

## 卸载

如果需要卸载 Operator：

```bash
# 删除监控实例
kubectl delete podmonitor --all --all-namespaces

# 删除 Operator
kubectl delete -f config/manager/manager.yaml

# 删除 RBAC
kubectl delete -f config/rbac/

# 删除命名空间
kubectl delete namespace podmonitor-system

# 删除 CRD（可选，会影响其他命名空间的资源）
kubectl delete -f config/crd/bases/podmonitor.pod-monitor.io_podmonitors.yaml
```

## 下一步

部署完成后，你可以：

1. 根据实际需求调整监控配置
2. 配置告警规则（如使用阿里云 ARMS）
3. 集成到 CI/CD 流程中
4. 监控 Operator 的运行状态

祝你部署顺利！如有问题，请查看日志或联系支持。

