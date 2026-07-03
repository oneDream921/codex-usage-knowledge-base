# 案例：Codex 自动验证 VPS 部署脚本

## 背景

项目：`E:\my-project\xray-vps-offline-deployer`

目标：

- 验证 Windows 本地打包上传部署。
- 验证 VPS 直接从 GitHub 克隆部署。
- 修复脚本中的卡点。
- 形成简明操作文档和实测状态表。

## Codex 实际使用的工具

- 本地 PowerShell：运行 Windows 打包、Git、文件检查。
- Bash/WSL：运行 `scripts/verify-bundle.sh`。
- `apply_patch`：修改 Bash、PowerShell 脚本和 Markdown 文档。
- Python + Paramiko：自动登录 VPS、执行命令、下载验证产物。
- Git：提交和推送本地修复，确认 GitHub 远端提交。

## 自动化验证步骤

### 1. 本地确认

```bash
git status --short
git rev-parse HEAD
git ls-remote https://github.com/oneDream921/xray-vps-offline-deployer.git refs/heads/main
```

目的：

- 确认本地工作区是否干净。
- 确认 GitHub 远端是否包含最新修复。
- 避免 VPS 克隆旧版本脚本。

### 2. 远程 clean state 检查

Codex 使用 Paramiko 连接 VPS 后，先检查：

```bash
awk -F= '/^PRETTY_NAME=/{gsub(/"/,"",$2); print $2}' /etc/os-release
uname -m
systemctl is-active xray
test -e /etc/systemd/system/xray.service
test -e /usr/local/bin/xray
test -e /usr/local/etc/xray
ss -ltnp | grep ':443'
```

目的：

- 确认系统是 Ubuntu 22.04 x64。
- 确认没有半安装残留。
- 确认 `443/tcp` 没被占用。

### 3. 方式一：Windows 打包上传部署

验证内容：

- `scripts/windows/package.ps1`
- 上传离线 ZIP。
- 远程 dry-run。
- 正式部署。
- 下载 `/root/xray-client/`。

验证结果：

- Windows + Ubuntu 22.04 x64：已实测通过。

### 4. 方式二：VPS 直接 clone GitHub 部署

远程执行：

```bash
apt-get update
apt-get install -y git make zip unzip ca-certificates
cd /tmp
rm -rf xray-vps-offline-deployer
git clone https://github.com/oneDream921/xray-vps-offline-deployer.git
cd xray-vps-offline-deployer
make verify
bash scripts/deploy.sh --server-ip "156.226.183.47" --listen-port 443 --reality-sni "dl.google.com" --dry-run
bash scripts/deploy.sh --server-ip "156.226.183.47" --listen-port 443 --reality-sni "dl.google.com" --configure-ufw
```

验证结果：

- VPS 直接 GitHub clone + Ubuntu 22.04 x64：已实测通过。

## 修复和沉淀

本次过程中沉淀出的改进：

- Windows 远程脚本自动补装 `unzip`。
- 部署脚本监听端口检测增加等待，避免服务刚启动时误判。
- 支持 Ubuntu 22.04/24.04 和 CentOS/RHEL 系 7/8/9。
- `xray-client/` 和 `xray-client-method2/` 加入忽略和敏感扫描排除。
- README 增加实测状态表。
- 新增 Windows 简明部署文档和 VPS 直接 clone 部署文档。

## 踩坑

### VPS 重置后 SSH 指纹变化

现象：

```text
WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!
```

处理：

```powershell
ssh-keygen -R 156.226.183.47
```

### VPS 刚重置后 SSH 被关闭

现象：

```text
Connection closed by 156.226.183.47 port 22
```

处理：

- 等 1-2 分钟。
- 先单独 `ssh root@IP` 确认可登录。
- 再跑部署脚本。

### GitHub clone 和 apt 较慢

原因：

- 新 VPS 首次 `apt-get update/install` 需要下载索引和工具。
- 仓库包含 Xray ZIP，GitHub clone 约几十 MB。

处理：

- 等待完成。
- 如果 VPS 访问 GitHub 不稳定，改用 Windows 本地打包上传方式。

## 可复用提示词

```text
请你用 Codex 自动验证这台 VPS 上的部署脚本。先检查 clean state，再执行 dry-run，最后正式部署。验证 service active、端口监听、配置测试和产物存在。不要把密码写入仓库，不要提交客户端敏感配置。
```

