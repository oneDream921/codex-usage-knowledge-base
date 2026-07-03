# 用 PowerShell Profile 固定 UTF-8 编码

## 原因

在 Windows PowerShell 5.1 里，控制台代码页、输入输出编码、管道编码经常不是一套东西。

常见现象是：PowerShell 自己显示中文还行，但一经过 `git`、`mvn`、`npm`、`python`、`cmd`、`rg` 这些外部命令，中文输出、中文文件内容或管道传参就可能乱码。

本次沉淀这个技巧的直接原因是：当前环境里控制台代码页是 `936`，输入编码是 GB2312，`[Console]::OutputEncoding` 是 UTF-8，但 `$OutputEncoding` 还是 US-ASCII。这个组合会让 Codex 在 Windows PowerShell 中读取中文文档、执行脚本和判断输出时不稳定。

## 解决

先检查当前状态：

```powershell
$PSVersionTable.PSVersion
chcp
[Console]::InputEncoding
[Console]::OutputEncoding
$OutputEncoding
```

查看当前用户 PowerShell profile 路径：

```powershell
$PROFILE.CurrentUserCurrentHost
```

如果 profile 文件不存在，创建目录：

```powershell
New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE.CurrentUserCurrentHost) | Out-Null
```

把下面内容写入当前用户 profile：

```powershell
# Keep Windows PowerShell 5.1 console, pipeline, and common file output on UTF-8.
# This is scoped to the current user and current host only.

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

try {
    chcp.com 65001 > $null
} catch {
}

[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$env:LESSCHARSET = 'utf-8'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Export-Csv:Encoding'] = 'utf8'
```

如果要用命令直接写入，可以这样做：

```powershell
$profilePath = $PROFILE.CurrentUserCurrentHost
New-Item -ItemType Directory -Force -Path (Split-Path $profilePath) | Out-Null

@'
# Keep Windows PowerShell 5.1 console, pipeline, and common file output on UTF-8.
# This is scoped to the current user and current host only.

$utf8NoBom = New-Object System.Text.UTF8Encoding $false

try {
    chcp.com 65001 > $null
} catch {
}

[Console]::InputEncoding = $utf8NoBom
[Console]::OutputEncoding = $utf8NoBom
$OutputEncoding = $utf8NoBom

$env:PYTHONUTF8 = '1'
$env:PYTHONIOENCODING = 'utf-8'
$env:LESSCHARSET = 'utf-8'

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$PSDefaultParameterValues['Set-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Add-Content:Encoding'] = 'utf8'
$PSDefaultParameterValues['Export-Csv:Encoding'] = 'utf8'
'@ | Set-Content -LiteralPath $profilePath -Encoding UTF8
```

重新打开一个 PowerShell 窗口后验证：

```powershell
chcp
[Console]::InputEncoding.WebName
[Console]::OutputEncoding.WebName
$OutputEncoding.WebName
'中文测试'
cmd /c echo 中文CMD测试
```

期望看到：

```text
Active code page: 65001
utf-8
utf-8
utf-8
中文测试
中文CMD测试
```

## 效果

新打开的 Windows PowerShell 会话会默认使用 UTF-8。

实际效果是：

```text
1. PowerShell 管道传中文给外部命令时更稳定。
2. 外部命令输出中文时更不容易乱码。
3. Set-Content、Out-File、Export-Csv 等常见写文件命令默认写 UTF-8。
4. Codex 在 Windows PowerShell 里读取中文项目文档、执行脚本和判断输出时更可靠。
```

## 注意

- 这个方法只改当前用户的 PowerShell profile，不改系统全局区域设置。
- 已经打开的 PowerShell 窗口不会自动生效，需要关闭后重新打开。
- 不建议优先打开 Windows 的“Beta: 使用 Unicode UTF-8 提供全球语言支持”。那个影响面更大，可能让老软件或安装器出问题。
- PowerShell 7 的 UTF-8 默认行为更好。如果以后可以安装 `pwsh`，优先用 PowerShell 7。
