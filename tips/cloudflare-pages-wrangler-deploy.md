# 用 Wrangler CLI 让 Codex 部署 Cloudflare Pages

## 原因

Cloudflare Pages 支持网页拖拽上传静态文件，但用户如果不熟悉 Cloudflare Pages 的项目创建、上传和发布流程，很容易卡在页面操作上，不知道下一步该点哪里，也不确定部署成功后应该访问哪个域名。

更适合 Codex 接手的方式是安装并使用 Cloudflare 官方命令行工具 Wrangler。它可以让 Codex 在用户完成授权后，自动创建 Pages 项目、上传本地静态目录，并把 Cloudflare 返回的线上域名汇报给用户。

本次沉淀这个技巧的直接原因是：用户已经有可部署的静态网站产物，但对 Cloudflare Pages 的部署操作不熟练，希望 Codex 使用官方 CLI 自动完成部署，并直接给出可访问的 Pages 域名。

## 解决

先确认本地静态产物目录存在。以静态博客为例：

```powershell
Test-Path project\blog-generator\dist
Get-ChildItem -Recurse -File project\blog-generator\dist | Measure-Object
```

如果本机没有全局安装 Wrangler，可以先用 `npx` 临时运行。

临时运行的效果是：当前命令可以执行，npm 可能会留下下载缓存，但关闭终端后通常不会多出一个可直接使用的 `wrangler` 命令。下次还要继续写完整的 `npx ... wrangler` 命令。

有些 Windows 环境的默认 npm 源可能让 `npx wrangler` 长时间无返回。遇到这种情况，可以临时指定官方 npm registry，不需要修改全局 npm 配置：

```powershell
npx --yes --registry=https://registry.npmjs.org/ wrangler --version
```

如果希望以后长期复用，建议全局安装 Wrangler：

```powershell
npm install -g wrangler --registry=https://registry.npmjs.org/
```

安装后验证：

```powershell
wrangler --version
wrangler whoami
```

全局安装成功后，后面的命令可以把 `npx --yes --registry=https://registry.npmjs.org/ wrangler` 简化成 `wrangler`。如果 `wrangler --version` 正常，但 `wrangler whoami` 偶发 `fetch failed`，一般是 Cloudflare API 网络、代理或 VPN 问题，不代表安装失败，可以先重试。

登录 Cloudflare。下面仍用 `npx` 写法，适合没有全局安装的环境；如果已经全局安装，可以改成 `wrangler login`：

```powershell
npx --yes --registry=https://registry.npmjs.org/ wrangler login
```

这条命令会打开浏览器授权页。授权必须由用户自己完成，Codex 不应该代替用户输入账号密码或确认第三方 OAuth 授权。

登录后检查当前状态：

```powershell
npx --yes --registry=https://registry.npmjs.org/ wrangler whoami
npx --yes --registry=https://registry.npmjs.org/ wrangler pages project list --json
```

如果项目还不存在，先创建 Pages 项目：

```powershell
npx --yes --registry=https://registry.npmjs.org/ wrangler pages project create <pages-project-name> --production-branch=main
```

部署本地静态目录：

```powershell
npx --yes --registry=https://registry.npmjs.org/ wrangler pages deploy project/blog-generator/dist --project-name=<pages-project-name> --branch=main --commit-dirty=true --commit-message="Deploy static site"
```

部署完成后，用 HTTP 请求验收关键入口：

```powershell
$base = "https://<pages-project-name>.pages.dev"
$urls = @(
  "$base/",
  "$base/sitemap.xml",
  "$base/rss.xml",
  "$base/pagefind/pagefind.js"
)

foreach ($url in $urls) {
  $response = Invoke-WebRequest -Uri $url -UseBasicParsing -MaximumRedirection 5 -TimeoutSec 30
  [pscustomobject]@{
    Url = $url
    Status = $response.StatusCode
    Length = $response.RawContentLength
  }
}
```

最后检查工作区，避免把 Wrangler 临时缓存提交进去：

```powershell
git status --short
```

如果仓库里出现 `.wrangler/`，先确认它只是本地缓存，再清理或加入忽略规则。不要提交 Cloudflare 凭据、Token、账号 ID 或本地登录态。

## 效果

用了 Wrangler 后，Codex 可以完成这几件事：

- 确认本地 `dist` 是否可部署。
- 通过 Cloudflare OAuth 登录态上传静态文件。
- 自动创建 Pages 项目。
- 返回生产地址和本次部署地址。
- 用 `Invoke-WebRequest` 验证首页、Sitemap、RSS、搜索索引等入口。
- 最后检查 `git status`，避免把临时缓存或生成产物带进 Git。

实际效果是：Cloudflare Pages 部署从“用户自己摸索页面操作”变成“用户只负责授权，Codex 负责创建项目、上传产物、返回域名和验收结果”。

## 注意

不要把这些内容写进仓库：

- Cloudflare 账号邮箱
- Cloudflare Account ID
- API Token
- OAuth 登录态
- 真实项目私有域名

Wrangler 登录凭据通常保存在当前用户目录，不应该复制到项目里。

如果只想做一次临时验证，网页拖拽 ZIP 仍然是最低成本方案；如果要让 Codex 反复部署、验收和复盘，Wrangler 更适合。
