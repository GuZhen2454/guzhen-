---
description: 证据文件、章节封面映射、复现工具，以及公开前的脱敏命令。
---

# 附录：证据与复现

## 证据文件

书里标了【实测】的结论，原始输出都在这几个文件里。它们是 JSON/纯文本，可以直接打开核对，也可以当回归基线。

| 文件 | 内容 |
|---|---|
| [`evidence/env-snapshot.json`](evidence/env-snapshot.json) | 本机环境快照：版本、渠道、profile、bundle、模型、沙箱、运行时 |
| [`evidence/tree.txt`](evidence/tree.txt) | 工作区与 `~/.dsh` 的全量文件树 |
| [`evidence/cordis.patch.copy.yml`](evidence/cordis.patch.copy.yml) | profile 的 patch 层副本（只读参考） |
| [`evidence/profile-package.copy.json`](evidence/profile-package.copy.json) | profile 的 bundle 声明副本 |

## 章节封面

视频的六张章节封面已存档，文件名按时间点命名，可直接对照画面。其中四张作为插图放在对应页首；导入与总结两张只在下面这张表里。

| 时间点 | 视频章节 | 文件 | 出现位置 |
|---|---|---|---|
| 0:00 | 导入 | `assets/frames/00-intro.jpg` | 仅本表 |
| 0:45 | 技术概念 | `assets/frames/01-concepts.jpg` | [技术概念](01-concepts.md) |
| 5:07 | 安装配置 | `assets/frames/02-install.jpg` | [体检与安装](02-install.md) |
| 13:13 | 使用教程 | `assets/frames/03-usage.jpg` | [使用入门](03-usage.md) |
| 30:50 | 插件实战 | `assets/frames/04-plugins.jpg` | [插件实战](05-plugins.md) |
| 47:18 | 总结 | `assets/frames/05-summary.jpg` | 仅本表 |

## 复现工具

| 文件 | 作用 | 状态 |
|---|---|---|
| `tools/check-book.ps1` | 本书的结构检查器：目录完整性、链接可解析、无孤儿页面、无页面内中文锚点 | 可用 |
| `tools/build-book.ps1` | 最初把单文件版手册切成这个目录结构的脚本。**一次性工具**：源文件已拆完，现在重跑没有意义，保留只为说明拆分规则 | 归档 |
| `tools/asar-read.mjs` | 实验性的 Electron ASAR 读取器 | **未跑通**：沙箱禁止读 `app.asar`，保留思路 |

跑检查器：

```powershell
cd dsh-lab
.\tools\check-book.ps1
```

退出码 0 表示目录、链接、图片、front matter 四项全过。

## 公开前的脱敏

证据文件里保留了真实的用户目录（含用户名 `guzhen`）。如果要公开发布，先跑一次替换，**默认不会自动执行**：

```powershell
$user = $env:USERPROFILE                      # 你的真实用户目录
Get-ChildItem .\evidence -File | ForEach-Object {
  $t = Get-Content $_.FullName -Raw
  $t = $t -replace [regex]::Escape($user), 'C:\Users\<user>'
  Set-Content $_.FullName $t -NoNewline
}
```

正文页面已经做过这层替换（用的是 `%USERPROFILE%`），所以只有 `evidence/` 需要处理。

## 视频数据的来源

两处接口，都绕开了网页验证码：

- `api.bilibili.com/x/web-interface/view?bvid=BV1REx46NEc4` —— 标题、时长（3041 秒）、播放/点赞/收藏、UP 主。
- `api.bilibili.com/x/player/v2?aid=…&cid=…` —— `view_points` 章节列表，以及 `subtitle` 字段（为空，这是没有公开字幕的证据）。

章节封面来自 `i0.hdslb.com/bfs/vchapter/<cid>_<秒数>.jpg`。

---

回到[写在前面](00-preface.md)，或从[速查表](08-cheatsheet.md)开始查东西。
