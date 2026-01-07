# PodMonitor Operator

一个 Kubernetes Operator，用于监控集群中的 Pod 运行时长，自动检测和清理僵尸 Pod。

## 功能特性

- 🔍 **自动监控**: 定期检查指定命名空间中的 Pod 运行状态
- 🧟 **僵尸 Pod 检测**: 自动识别超过最大运行时长的 Pod
- 🧹 **自动清理**: 可配置自动清理僵尸 Pod，释放资源（⚠️ **风险提示**：启用后会自动删除 Pod，请谨慎使用）
- 🏷️ **标签过滤**: 支持通过标签选择器过滤要监控的 Pod
- 📊 **状态报告**: 提供详细的监控状态和僵尸 Pod 列表（运行时长以天为单位显示）
- 📧 **邮件通知**: 自动发送僵尸 Pod 告警邮件给运维团队

## 快速开始

### 前置要求

- Kubernetes 1.20+
- Helm 3.0+（推荐）或 kubectl
- 镜像仓库访问权限

### 使用 Helm 安装（推荐）

```bash
helm repo add podmonitor https://geekzx.github.io/pod-monitor/charts
helm repo update
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=ghcr.io/geekzx/podmonitor-controller \
  --set image.tag=v1.0.0 \
  --set image.pullPolicy=Always
```

详细安装步骤和配置请参考 [Helm 部署指南](HELM_DEPLOY.md)

## 配置说明

### PodMonitor 资源字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `namespaces` | `[]string` | 否 | 要监控的命名空间列表（空则监控所有命名空间） |
| `labelSelector` | `map[string]string` | 否 | 标签选择器，用于过滤 Pod |
| `maxRunDurationSeconds` | `int64` | 是 | 最大运行时长（秒），超过此时间视为僵尸 Pod |
| `checkIntervalSeconds` | `int64` | 否 | 检查间隔（秒），默认 60 |
| `autoCleanup` | `bool` | 否 | 是否自动清理僵尸 Pod，默认 false。⚠️ **警告**：设置为 `true` 时，Operator 会自动删除超过最大运行时长的 Pod，可能导致数据丢失或服务中断，请在生产环境谨慎使用 |
| `gracePeriodSeconds` | `int64` | 否 | 清理前的宽限期（秒），默认 300 |
| `emailNotification` | `EmailNotificationConfig` | 否 | 邮件通知配置 |

### 邮件通知配置

```yaml
emailNotification:
  enabled: true
  recipients:
    - ops-team@example.com
  smtpServer: smtp.example.com
  smtpPort: 587
  from: podmonitor@example.com
  useTLS: true
  # password 建议通过 Kubernetes Secret 设置环境变量 SMTP_PASSWORD
```

## 查看监控状态

```bash
kubectl get podmonitor -A
kubectl get podmonitor <name> -n <namespace> -o yaml
kubectl logs -n podmonitor-system -l app.kubernetes.io/name=podmonitor-operator -f
```

状态信息包括：`totalPods`、`zombiePods`、`cleanedPods`、`lastCheckTime`、`zombiePodList`（包含运行时长、状态、创建时间等）

## 开发

### 本地运行

```bash
# 安装 CRD
make install

# 本地运行
make run
```

### 构建镜像

```bash
docker build -t ghcr.io/geekzx/podmonitor-controller:v1.0.0 .
docker push ghcr.io/geekzx/podmonitor-controller:v1.0.0
```

详细构建和发布步骤请参考 [构建和发布镜像指南](BUILD_AND_PUBLISH.md)

## 卸载

```bash
helm uninstall podmonitor-operator -n podmonitor-system
kubectl delete namespace podmonitor-system
```

## 相关文档

- [Helm 部署指南](HELM_DEPLOY.md) - 详细的 Helm 安装和配置
- [快速开始](QUICKSTART.md) - 本地开发和测试
- [构建和发布镜像](BUILD_AND_PUBLISH.md) - 镜像构建和发布到不同仓库
- [发布 Helm Chart](PUBLISH_HELM.md) - Helm Chart 发布

## 许可证

MIT License
