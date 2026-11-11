---
description: 为什么 enabled: false 的功能还能用：profile、预设、客户端三层开关，以及怎么真的开一个能力。
---

# 功能到底开没开：三层开关的真相

这一章是「开一个 inactive 功能」这条指令的真实调查结果，也是整份手册里最容易被误判的地方。结论先说：**`inactive` / `enabled: false` 不等于这个功能用不了。**

## 现场：plan-mode 在插件树里是「关着的」

```text
plugin_manager list_plugins → include:plan-mode
  { "moduleName": "@deepseek-ai/dsh-plan-mode", "enabled": false, "fiberPhase": null }
```

同一个输出里，还有一批「明明能用却报 false」的行：

| 行 | enabled | 可它对应的能力 | 我实际有这个能力吗 |
|---|---|---|---|
| `include:tool-fs` | **false** | read / write / edit / glob / grep | ✅ 用了一整晚 |
| `include:tool-todo` | **false** | todo_write | ✅ 用过 |
| `include:tool-goal` | **false** | create_goal / update_goal | ✅ 用过 |
| `include:tool-pwsh` | **false** | pwsh 终端 | ✅ 用过 |
| `include:plan-mode` | **false** | `/plan`、exit_plan_mode | 见下文 |

所以这张表**不能**当「功能开关面板」用。它报的是 profile 根层的行状态。

## 真正的原因：能力是「预设」挂的，不是 profile 挂的

打开你这台机器正在用的预设文件（`@deepseek-ai/dsh-web-app/presets/cordis.patch.yml`，138 行）就能看到真相 —— `tool-fs`、`tool-todo`、`tool-goal`、`exit_plan_mode` 的实例全在这里：

```yaml
# presets/cordis.patch.yml 第 47–67 行（节选）
- id: planning
  name: cordis:group
  group: true
  isolate:
    planMode: true
  config:
    - id: plan-mode
      name: '@deepseek-ai/dsh-plan-mode'
      config:
        section: |
          You are in plan mode. Stay in plan mode until the user approves your plan
          through exit_plan_mode or switches the session mode. ...
```

**也就是说：`cordis` 预设里 plan mode 早就编好了，而且还给它开了一个隔离域（`isolate: planMode`）。** 根层那条 `include:plan-mode` 只是个被 web-app 覆盖层禁掉的占位行，防止同一个服务在根层重复注册。

三层结构可以这么记：

```
① profile 根层（~/.dsh/profiles/desktop/cordis.patch.yml）
   └─ 全局服务：模型、会话、沙箱、存储、web、审批……（一次性，所有会话共享）
② 预设层（preset-cordis 的 config.plugins）
   └─ 每个 agent 的能力：工具、persona、plan-mode、压缩、子代理、技能
      ↑ 会话在创建时固化一个预设版本；之后改预设，老会话不跟着变
③ 客户端层（Web UI 的 slot）
   └─ 界面上的控件：plan 按钮、权限选择器、模型选择器
```

所以「开一个功能」要先问：**它是全局服务（改 profile），还是每个 agent 的能力（改预设）？**

## 结论：plan mode 不需要「开」，它已经是开的

三条证据叠起来：

1. `cordis` 预设第 47–67 行已经 `insert` 了 plan-mode，带完整 guidance 文本 —— 不是被禁用的行。
2. 本机 `selectedDefault: cordis`，正是这个预设。
3. 客户端 `conversation.input.plan` 这个 composer 插槽 `available: true`，且已有一个 `active: true` 的占用者 —— 界面上的 plan 控件是活的。

**如果这时候再装一个 bundle 去「打开」plan-mode，最可能的结果是同一个 `/plan` 命令被注册两遍。** 这就是为什么我没有动手装。

## 怎么真的验收（一步）

在输入框里打：

```text
/plan 帮我把 dsh-lab 这本手册重构成一本可发布的 GitBook 结构
```

预期：模式切到 planning，我进入「只读探索 + 出方案」状态，最后调 `exit_plan_mode` 给你一张方案审阅卡；你点 `Approve` 才开工，点 `Keep planning` 我继续改方案。退出：`/plan off`。

> 这也解释了为什么我（agent）现在工具列表里没有 `exit_plan_mode`：它是「进入 plan mode 之后才逐步披露」的工具，没进 plan mode 就不会出现。

## 那「真的关着」的功能长什么样，怎么开

真关着的，是预设里**根本没有这行**、或者被显式 `disabled` 的。本机几个例子：

| 能力 | 状态 | 证据 |
|---|---|---|
| `apply_patch` 工具 | 关 | 预设里 `tool-fs` 的 `config.applyPatch: false` |
| 终端工具（`terminal_open` 等） | 关 | 预设里没有对应的 tool 行，只有宿主 `terminals` 服务 |
| Agent Teams（`spawn_teammate`、`team_task_*`） | 关 | `agentTeams` 服务在，但没有 tool 行挂它 |
| 会话全文检索 | 关 | `session-query-sqlite` 的 `openAt: never`（注释明说：搜索会报 `SESSION_QUERY_SEARCH_DISABLED`） |

**开法（官方路径，两条）：**

```yaml
# 路径 A：改预设 —— 给 cordis 预设加一行
# 注意：override 会整体替换 config，plugins 必须原样重述全部 138 行，漏一行就少一个能力
- id: preset-cordis
  name: '@deepseek-ai/dsh-agent-preset'
  config:
    id: cordis
    order: 4
    plugins:
      # ……原样抄第 13–138 行……
      - id: plan-mode-something-new
        name: '@deepseek-ai/dsh-xxx'

# 路径 B：改 profile 根层 —— 只适合全局服务（模型、存储、沙箱、web）
- id: session-query-sqlite
  name: '@deepseek-ai/dsh-session-query-sqlite'
  config:
    path: ':memory:'
    openAt: startup          # 打开全文检索
```

然后**不要**手写 `~/.dsh/profiles/desktop/cordis.patch.yml`。写成工作区里的一个 bundle 目录（`package.json` 带 `dsh.bundle.patch` + 一个 `cordis.patch.yml`），交给 `plugin_manager install_bundle` —— 它会自己完成安装与选择，且返回 `application` 与 `warnings` 告诉你到底生效没有。

## 这一节的教训

1. 看功能开没开，**别信一个 `enabled` 字段**；先分清「全局服务」还是「agent 预设能力」。
2. 改预设是**整体替换**，漏写一行等于删一个能力 —— 这就是为什么 override 前必须把原文件完整抄一遍。
3. 老会话不会跟着预设变：**验证一定要开新会话**。
4. 我在[插件实战](05-plugins.md)最早写的「inactive 里藏着好东西，想开就在 patch 里加条目」是错的，已在此更正。

---

证据文件清单、封面映射与脱敏命令都在[附录](09-appendix.md)。

