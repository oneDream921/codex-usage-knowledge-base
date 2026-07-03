# Codex 使用技巧知识库

这个仓库只记录我实际用过、值得复用的 Codex 小技巧。

每个技巧统一使用三个部分：

```text
原因：为什么需要这个技巧。
解决：具体怎么做。
效果：用了以后能得到什么结果。
```

原则：

- 一个技巧一个文件。
- 只写最小可复用步骤。
- 不写长篇复盘。
- 不记录真实密码、Token、私钥或客户端配置。
- 首次克隆后运行 `.\scripts\install-git-hooks.ps1`，提交时自动检查敏感信息。
- 开源前运行 `.\scripts\check-sensitive.ps1`，避免提交真实密钥、代理链接或服务器配置。

## 技巧列表

- [用 Paramiko 让 Codex 登录 VPS 执行命令](tips/paramiko-ssh-login.md)
- [用 PowerShell Profile 固定 UTF-8 编码](tips/powershell-utf8-profile.md)
