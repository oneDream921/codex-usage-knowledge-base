# 用 Paramiko 让 Codex 登录 VPS 执行命令

## 原因

有些任务需要在 VPS 上反复执行命令，例如部署脚本、检查服务状态、查看端口监听、下载生成文件。

如果全部人工操作，过程会很碎：复制命令、登录服务器、输入密码、粘贴输出、再让 Codex 判断下一步。使用 Paramiko 后，Codex 可以通过 Python 直接登录 VPS，自动执行命令并读取结果。

本次沉淀这个技巧的直接原因是：Codex 直接通过 PowerShell 调用 `ssh` / `scp` 时，容易卡在交互式密码输入、首次 SSH 指纹确认、长时间命令输出等环节，不适合稳定地自动跑完整验证流程。

## 解决

建议装在当前仓库的虚拟环境里：

```powershell
python -m venv .venv-paramiko
.\.venv-paramiko\Scripts\python.exe -m pip install -i https://pypi.tuna.tsinghua.edu.cn/simple paramiko
```

验证：

```powershell
@'
import paramiko
print("paramiko OK", paramiko.__version__)
'@ | .\.venv-paramiko\Scripts\python.exe -
```

然后把服务器信息告诉 Codex，例如：

```text
服务器 IP: x.x.x.x
用户名: root
密码: 只在当前任务中使用
请用 Paramiko 登录服务器，执行部署验证。
不要把密码写入仓库文件。
```

最小 Python 示例：

```python
import os
import paramiko

host = "服务器IP"
user = "root"
password = os.environ["VPS_PASSWORD"]

client = paramiko.SSHClient()
client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
client.connect(hostname=host, username=user, password=password, timeout=30)

stdin, stdout, stderr = client.exec_command("uname -a && systemctl is-active xray || true")
print(stdout.read().decode("utf-8", errors="replace"))
print(stderr.read().decode("utf-8", errors="replace"))

client.close()
```

PowerShell 中临时传密码：

```powershell
$env:VPS_PASSWORD='这里填本次密码'
.\.venv-paramiko\Scripts\python.exe .\your-script.py
Remove-Item Env:\VPS_PASSWORD
```

## 效果

Codex 可以自动完成这些工作：

```text
1. SSH 登录 VPS
2. 执行远程命令
3. 检查 systemctl 状态
4. 检查端口监听
5. 上传或下载文件
6. 收集验证输出
```

实际效果是：服务器部署验证可以从“人工复制粘贴多轮输出”变成“Codex 自动跑完整流程并汇总结果”。

## 展望

这个技巧不只适合部署验证。后续也可以让 Codex 通过终端控制服务器，做更完整的自动优化流程，例如：

```text
1. 检查系统版本、CPU、内存、磁盘和端口。
2. 分析服务状态和日志。
3. 调整配置文件。
4. 重启服务并验证效果。
5. 输出优化前后的对比结果。
```

关键是仍然要保持边界：Codex 可以执行和验证，但涉及删除数据、修改防火墙、重启关键服务等高风险操作时，应先让用户确认。

## 注意

- 不要把密码写进 `.py` 文件。
- 不要提交下载下来的客户端配置、私钥、Token。
- 远程部署前先检查服务器是否干净，避免重复安装。
