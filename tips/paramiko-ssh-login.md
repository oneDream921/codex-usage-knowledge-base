# 用 Paramiko 让 Codex 登录 VPS 执行命令

用途：让 Codex 通过 Python 自动登录 VPS，执行远程命令、检查服务状态、下载验证文件。

## 安装

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

## 给 Codex 的用法

把服务器信息告诉 Codex，例如：

```text
服务器 IP: x.x.x.x
用户名: root
密码: 只在当前任务中使用
请用 Paramiko 登录服务器，执行部署验证。
不要把密码写入仓库文件。
```

Codex 可以用它做这些事：

```text
1. SSH 登录 VPS
2. 执行远程命令
3. 检查 systemctl 状态
4. 检查端口监听
5. 上传或下载文件
6. 收集验证输出
```

## 最小 Python 示例

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

## 注意

- 不要把密码写进 `.py` 文件。
- 不要提交下载下来的客户端配置、私钥、Token。
- 远程部署前先检查服务器是否干净，避免重复安装。
