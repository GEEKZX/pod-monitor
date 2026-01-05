# 发布 Helm Chart 到 GitHub 完整指南

本指南将帮助你将 PodMonitor Operator 的 Helm Chart 发布到 GitHub，让其他人可以通过 Helm Repository 直接安装。

## 前置要求

1. **GitHub 账号**（你已有）
2. **Git 已安装并配置**
3. **Helm 3.x 已安装**（检查：`helm version`）
   - **Windows 安装 Helm**：
     - 方式 1（推荐）：使用 Chocolatey - `choco install kubernetes-helm`
     - 方式 2：使用 winget - `winget install Helm.Helm`
     - 方式 3：手动下载 - 从 [Helm Releases](https://github.com/helm/helm/releases) 下载 Windows 版本，解压后添加到 PATH
4. **项目已初始化为 Git 仓库**（如果没有，需要先初始化）

## 步骤 1: 准备 GitHub 仓库

### 1.1 创建新仓库（如果还没有）

1. 登录 GitHub
2. 点击右上角 `+` -> `New repository`
3. 填写信息：
   - **Repository name**: `pod-monitor`（或你喜欢的名字）
   - **Description**: `Kubernetes Operator for monitoring zombie pods`
   - **Visibility**: Public（推荐，这样别人可以使用）或 Private
   - **不要**勾选 "Initialize this repository with a README"（如果本地已有代码）
4. 点击 `Create repository`

### 1.2 获取仓库 URL

创建后会显示仓库 URL，格式类似：
- HTTPS: `https://github.com/your-username/pod-monitor.git`
- SSH: `git@github.com:your-username/pod-monitor.git`

**记录下这个 URL，后面会用到！**

## 步骤 2: 初始化本地 Git 仓库（如果还没有）

```bash
# 在项目根目录执行
cd d:\job_monitor

# 检查是否已经是 Git 仓库
git status

# 如果不是，初始化
git init
git add .
git commit -m "Initial commit: PodMonitor Operator"
```

## 步骤 3: 连接到 GitHub 仓库

```bash
# 添加远程仓库（替换为你的实际 URL）
git remote add origin https://github.com/your-username/pod-monitor.git

# 或者使用 SSH（如果你配置了 SSH key）
# git remote add origin git@github.com:your-username/pod-monitor.git

# 验证远程仓库
git remote -v
```

## 步骤 4: 打包 Helm Chart

```bash
# 确保在项目根目录
cd d:\job_monitor

# 打包 Chart（会生成 .tgz 文件）
helm package ./helm/podmonitor-operator

# 检查生成的文件
ls -la podmonitor-operator-*.tgz
# 应该看到类似: podmonitor-operator-0.1.0.tgz
```

## 步骤 5: 创建 charts 目录并组织文件

```bash
# 创建 charts 目录（用于存放打包的 Chart）
mkdir -p charts

# 移动打包文件到 charts 目录
mv podmonitor-operator-*.tgz charts/

# 生成 Helm Repository 索引文件
helm repo index charts/

# 检查生成的文件
ls -la charts/
# 应该看到:
# - index.yaml (索引文件)
# - podmonitor-operator-0.1.0.tgz (Chart 包)
```

## 步骤 6: 更新 .gitignore（可选）

确保 charts 目录不会被忽略：

```bash
# 检查 .gitignore
cat .gitignore

# 如果 charts/ 被忽略了，需要从 .gitignore 中移除或注释掉
# 通常 charts/ 目录应该被提交到 Git
```

## 步骤 7: 提交并推送到 GitHub

```bash
# 添加 charts 目录
git add charts/

# 提交
git commit -m "Add Helm chart v0.1.0"

# 推送到 GitHub（首次推送）
git branch -M main  # 如果分支不是 main，重命名为 main
git push -u origin main

# 如果遇到认证问题，可能需要：
# - 使用 Personal Access Token（推荐）
# - 或配置 SSH key
```

## 步骤 8: 启用 GitHub Pages

1. 在 GitHub 上打开你的仓库
2. 点击 `Settings`（设置）
3. 在左侧菜单找到 `Pages`
4. 在 `Source` 部分：
   - 选择 `Deploy from a branch`
   - Branch: 选择 `main`（或你的主分支）
   - Folder: 选择 `/ (root)` 或 `/charts`
   - 点击 `Save`
5. 等待几分钟，GitHub 会显示你的 Pages URL，格式类似：
   ```
   https://your-username.github.io/pod-monitor/
   ```

## 步骤 9: 验证发布

### 9.1 检查索引文件是否可访问

在浏览器中打开：
```
https://your-username.github.io/pod-monitor/charts/index.yaml
```

应该能看到 YAML 格式的索引内容。

### 9.2 测试添加仓库

```bash
# 添加你的 Helm 仓库
helm repo add podmonitor https://your-username.github.io/pod-monitor/charts

# 更新仓库列表
helm repo update

# 搜索你的 Chart
helm search repo podmonitor

# 应该看到:
# NAME                              CHART VERSION   APP VERSION   DESCRIPTION
# podmonitor/podmonitor-operator    0.1.0           1.0.0         A Kubernetes Operator for monitoring...
```

### 9.3 测试安装（可选）

```bash
# 查看 Chart 信息
helm show chart podmonitor/podmonitor-operator

# 查看 values
helm show values podmonitor/podmonitor-operator

# 测试安装（dry-run）
helm install test podmonitor/podmonitor-operator --dry-run --debug
```

## 步骤 10: 更新 Chart 版本（未来发布新版本时）

当你需要发布新版本时：

```bash
# 1. 修改 Chart.yaml 中的 version（例如从 0.1.0 改为 0.2.0）
# 编辑: helm/podmonitor-operator/Chart.yaml

# 2. 重新打包
helm package ./helm/podmonitor-operator

# 3. 移动新版本到 charts 目录
mv podmonitor-operator-0.2.0.tgz charts/

# 4. 更新索引（重要：这会合并新版本到现有索引）
helm repo index charts/ --merge charts/index.yaml

# 5. 提交并推送
git add charts/
git commit -m "Release Helm chart v0.2.0"
git push
```

## 常见问题

### Q1: 推送时提示认证失败

**解决方案：**
1. 使用 Personal Access Token：
   - GitHub -> Settings -> Developer settings -> Personal access tokens -> Tokens (classic)
   - 生成新 token，勾选 `repo` 权限
   - 推送时使用 token 作为密码

2. 或配置 SSH key：
   ```bash
   # 生成 SSH key
   ssh-keygen -t ed25519 -C "your_email@example.com"
   
   # 添加到 GitHub: Settings -> SSH and GPG keys
   # 然后使用 SSH URL: git@github.com:username/repo.git
   ```

### Q2: GitHub Pages 显示 404

**解决方案：**
- 确保 charts 目录在仓库根目录
- 确保 index.yaml 文件存在
- 等待几分钟让 GitHub 更新
- 检查 Pages 设置中的路径是否正确

### Q3: helm repo add 失败

**解决方案：**
- 检查 URL 是否正确（注意末尾的 `/charts`）
- 确保 GitHub Pages 已启用
- 尝试在浏览器直接访问 index.yaml URL

### Q4: 如何删除旧版本？

**解决方案：**
```bash
# 从 charts 目录删除旧版本文件
rm charts/podmonitor-operator-0.1.0.tgz

# 重新生成索引
helm repo index charts/

# 提交
git add charts/
git commit -m "Remove old chart version"
git push
```

## 使用你的 Chart

发布成功后，其他人可以这样使用：

```bash
# 添加仓库
helm repo add podmonitor https://your-username.github.io/pod-monitor/charts
helm repo update

# 安装
helm install podmonitor-operator podmonitor/podmonitor-operator \
  --namespace podmonitor-system \
  --create-namespace \
  --set image.repository=your-registry/podmonitor-controller \
  --set image.tag=v1.0.0
```

## 自动化脚本

我创建了一个自动化脚本 `scripts/publish-helm.sh`，可以简化发布流程。查看脚本获取更多信息。

---

**恭喜！** 你的 Helm Chart 现在已经发布到 GitHub，可以被全世界使用了！🎉

