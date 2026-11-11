---
description: 本机安装形态、首次启动生成物，以及三个真正值得改的配置项。
---

# 体检与安装（视频 5:07–13:13）

![体检与安装（视频 5:07–13:13）](assets/frames/02-install.jpg)

## 本机体检（对应视频「安装配置」章）

一次性结论，全部来自 `evidence/env-snapshot.json`【实测】：

| 项目 | 本机实际值 | 怎么确认的 |
|---|---|---|
| 应用形态 | 桌面端 Electron 应用 | 进程与安装目录 `F:\dfy\` |
| 主程序 | `F:\dfy\DeepSeek Harness.exe` | 文件存在 |
| 版本（产品号） | **0.2.2.0** | `VersionInfo.ProductVersion` |
| 版本（文件号） | **0.2.2-rc.1** | `VersionInfo.FileVersion` |
| 更新渠道 | `nightly` / `win-x64`，generic 源 `download.deepseek.com/dsh-desk/feeds/win-x64/` | `F:\dfy\resources\app-update.yml` |
| DSH 主目录 | `%USERPROFILE%\.dsh`（环境变量 `DSH_HOME`） | 环境变量 |
| Profile | `desktop`（`DSH_PROFILE`），目录 `~/.dsh/profiles/desktop` | 环境变量 |
| 启用的 bundle | `@deepseek-ai/dsh-base`、`@deepseek-ai/dsh-web-app` | profile 的 `package.json` |
| 默认模型 | `deepseek-account` / `deepseek-flash` / `reasoningEffort: high` | `cordis.patch.yml` |
| 预设 | `default: standard`，`selectedDefault: cordis` | `cordis.patch.yml` |
| 文件沙箱 | `workspace-write`（仅工作区可写） | 会话运行时策略 |
| 审批 | 已开启（越界操作会弹批准，拒绝则失败） | 会话运行时策略 |
| Web GUI | `http://127.0.0.1:62156` | `DSH_WEB_URL` |
| 内置运行时 | Node `24.21.0`、pnpm `11.28.5` | `F:\dfy\resources\runtime\versions.json` |
| 终端 | Windows PowerShell **5.1**.26100.9711（不是 pwsh 7） | `$PSVersionTable` |
| 插件树条目 | **199** 条（含 `schema` / `tree` / `inactive` / `absent` 四种状态） | Cordis Inspect `Config.listConfigs` |
| 内置技能包 | 7 个：`office`、`office-docx`、`office-pptx`、`office-xlsx`、`office-render`、`office-recalculate`、`office-export-pdf` | `F:\dfy\resources\runtime\office-skills\` |

**一个立刻能用的体检命令**（只读，直接粘到 PowerShell）：

```powershell
Get-Content "$env:USERPROFILE\Documents\deepseek-harness\default-workspace\dsh-lab\evidence\env-snapshot.json" -Raw |
  ConvertFrom-Json |
  Select-Object appVersion,appChannel,dshHome,dshProfile,pwsh,
    @{n='model';e={$_.model.provider + '/' + $_.model.model}},
    @{n='node';e={$_.runtime.node}} | Format-List
```

## 安装与首次运行（对应视频 5:07–13:13）

### 本机的安装形态

- 安装位置 `F:\dfy\`（用户自选盘符），主程序 `DeepSeek Harness.exe`，`resources/app.asar` 里打包了全部 JS 与 `node_modules`【实测】
- 更新走 **nightly** 渠道，说明你装的是每日构建版：`0.2.2-rc.1` 属于 RC，功能新但可能有坑
- 桌面端内嵌 Node `24.21.0`，所以**不需要**你系统里另装 Node（本机 `Get-Command node` 也确实找不到）【实测】

> ⚠️ 双版本号要注意：`ProductVersion` 显示 `0.2.2.0`，`FileVersion` 才是真实的 `0.2.2-rc.1`。报 bug 时报后者。

### 首次启动会生成什么

`~/.dsh/` 下的全部内容（这就是你的「用户数据」，备份/迁移只认这个目录）【实测】：

```
~/.dsh/
├── .anonymous-user-id          匿名 ID
├── .credentials.yaml           登录凭据（478 字节，别外发）
├── profiles/desktop/           你的 profile：4 个文件
├── sessions/                   会话记录（按工作区目录分文件夹）
├── storages/workspace.json     工作区注册表（716 字节）
├── attachments/v1/objects/     图片等附件（按 sha256 分桶存）
└── llm-deepseek/files-v3.json  模型侧文件索引
```

完整清单见 [`evidence/tree.txt`](evidence/tree.txt)（由后台任务 `pwsh-fc0269bb06444f75` 生成）【实测】。

### 三个真正值得改的配置

都在 `cordis.patch.yml` 里，改完**重启应用**生效【推断：patch 层由 Loader 在启动/重载时读取；热重载未在本机验证】。改完可以用 `plugin_manager` 的 `list_plugins` 看该条目的 `enabled` 与 `fiberPhase` 确认是否真的挂上了。

```yaml
# ① 换模型 / 调推理档位
- id: agent-default-model
  name: "@deepseek-ai/dsh-agent-default-model"
  config:
    provider: deepseek-account
    model: deepseek-flash      # 可换 deepseek-pro 等账号内可用模型
    reasoningEffort: high      # low / medium / high

# ② 换默认预设（预设决定「这个 agent 装了什么能力」）
- id: agent-preset-registry
  name: "@deepseek-ai/dsh-agent-preset-registry"
  config:
    default: standard
    selectedDefault: cordis    # 你现在用的是 cordis 预设

# ③ 调 UI 详细度（觉得聊天记录太啰嗦就改这里）
- id: ui-chat
  name: "@deepseek-ai/dsh-client-ui-chat"
  config:
    transcriptView: detailed   # 可改 compact
    performanceUsage: detailed
```

> 改 profile 会影响**所有会话**，不是当前这一个。改前先复制一份 `cordis.patch.yml`。

### 装好之后先做的三件事

1. **登录账号**：模型走 `deepseek-account`，凭据在 `~/.dsh/.credentials.yaml`【实测】
2. **开一个工作区**：沙箱是 `workspace-write`，只有工作区目录可写；你现在的工作区是 `%USERPROFILE%\Documents\deepseek-harness\default-workspace`
3. **确认审批行为**：越界操作会弹批准框；无人回答时**默认拒绝**（fail closed）
