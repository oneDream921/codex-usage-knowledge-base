# Codex 常用工具能力

本文记录本次 VPS 部署工作中实际用到的 Codex 能力。

## 本地 Shell

用途：

- 读取仓库文件。
- 执行 Git、PowerShell、Bash、Python。
- 运行本地验证命令，例如 `git diff --check`、`bash scripts/verify-bundle.sh`、PowerShell 打包脚本。

适合：

- 项目代码修改。
- 本地构建、打包、测试。
- Git 提交和状态检查。

注意：

- Windows 下避免把 Bash here-doc 直接写给 PowerShell。
- 中文文件用 UTF-8 读取和写入。

## apply_patch

用途：

- 创建或修改仓库文件。
- 保持变更可控，便于查看 diff。

适合：

- 修改脚本、文档、配置文件。
- 新增操作手册。

## Paramiko

用途：

- Codex 通过 Python 连接 VPS。
- 上传文件或执行远程命令。
- 自动采集远程验证结果。

本次用途：

- SSH 登录 Ubuntu 22.04 x64 VPS。
- 检查系统版本、端口、已有安装状态。
- 执行 `git clone`、`make verify`、`deploy.sh --dry-run`、正式部署。
- 验证 `systemctl is-active xray`、`ss -ltnp`、`xray run -test`。
- 下载 `/root/xray-client/` 中的客户端配置到本地测试目录。

注意：

- 不要把密码写入仓库文件。
- 密码只应临时放在当前进程环境变量或由用户手动输入。
- 下载的客户端配置属于敏感文件，必须加入 `.gitignore`。

## Git

用途：

- 确认本地提交是否已推送到 GitHub。
- 方式二验证前，用 `git ls-remote` 确认 VPS 将克隆到的远端提交。
- 提交脚本修复和文档沉淀。

关键点：

- 如果 VPS 直接从 GitHub 克隆，必须先确认本地最新修复已经 push。
- 否则 VPS 会拿到旧脚本，验证结果不代表当前本地代码。

