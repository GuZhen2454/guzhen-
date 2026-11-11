---
description: Inspect Provider 怎么读插件树、patch 层的三种写法与三条坑、加能力的四条路。
---

# 插件实战：改 config 而不是改代码（视频 30:50–47:18）

![插件实战：改 config 而不是改代码（视频 30:50–47:18）](assets/frames/04-plugins.jpg)

视频花了 16 分钟讲插件，是全片技术密度最高的部分。核心就一句：**DSH 的插件不是写死的，是 Loader 按条目挂载的；你能改的是条目。**

## 先学会看插件树

我作为 agent 有四个只读的 Inspect Provider，你也可以让我随时查：

| Provider | 看什么 | 本次用它干了什么 |
|---|---|---|
| `Config` | 每个 Loader 条目的 id、包名、状态、Config JSON Schema | 数出 **199** 条，看到 `schema`/`tree`/`inactive`/`absent` 四种状态 |
| `Tool` | 当前 Agent 能调用的全部工具 schema | 核对工具面 |
| `Service` | 宿主服务目录与方法签名（渐进式，先目录后单个契约） | 拿到 `skills`/`subagents`/`workflowEngine` 的真实方法签名 |
| `Slots` | Web UI 的实时插槽树（客户端） | 定位 UI 插件挂在哪 |

状态含义（这是读插件树的关键）：

- `schema` — 已挂载，有可校验的配置
- `tree` — 本身是容器（比如 `include`）
- `inactive` — 包在场但没启用（**这就是「能开没开」的功能**）
- `absent` — 声明了但当前组合里没有（**这就是「没装」**）

⚠️ **但别被 `inactive` 骗了** —— 这是下一章要讲的坑：`tool-fs`、`tool-todo`、`tool-goal`、`plan-mode` 在这张表里全是 `enabled: false`，可它们**在你的会话里明明都能用**。原因是这张表看的是 profile 根层的「占位行」，真正干活的实例是**每个 agent 的预设**挂的。详见 [功能开关](06-switches.md)。

## patch 层的最小写法

`cordis.patch.yml` 是一个 YAML 数组，每个元素是「按 id 定位 + 替换字段」。三种写法（方言细节以本机 `cordis-composition-reference` 技能为准）：

```yaml
# ① 改现有条目：带 id、不带 insert
- id: ui-chat
  name: "@deepseek-ai/dsh-client-ui-chat"   # 写 name 表示「确认是这家」，不是改名
  config:
    transcriptView: compact
    performanceUsage: detailed              # ⚠️ 必须把原字段全部重述！

# ② 关掉某个条目：给同一个 id 加 disabled
- id: agent-preset-registry
  name: "@deepseek-ai/dsh-agent-preset-registry"
  disabled: true                            # 支持 true / null / !!js 表达式

# ③ 插一个新条目：必须用 insert
- insert:
    - id: my-skill-provider
      name: "@deepseek-ai/dsh-skill-filesystem"
      config: {}
```

三条会直接坑到你的规则：

1. **`config` 是整体替换，不是深合并。** 你只写一个字段，其余字段就被抹掉了。想改哪条，先把那条的完整 config 抄下来再改。
2. **没有 `insert` 又没有非空 `id` 的补丁，或指向不存在的 id，会被静默跳过**（只在日志里警告）——“我明明改了却没生效”十有八九是这一条。
3. **`disabled` 可以是 `!!js` 表达式**，每次挂载都会重新求值，所以能写条件开关。

## 加能力的四条路，从易到难

| 路线 | 适合什么 | 风险 |
|---|---|---|
| ① 改 config / 开 `inactive` 条目 | 换个模型、开个工具、调 UI | 低，但影响所有会话 |
| ② 装现成 bundle / plugin | 加整块能力（新面板、新工具集） | 中；装包会跑构建脚本，需要显式批准 |
| ③ 自己写插件（Cordis） | 公司内部系统对接、自定义工具 | 高；要懂 Service/Event/Slot 契约 |
| ④ 接 MCP | 复用社区现成服务 | 中；注意权限边界 |

**本次没做的事，我如实标注：** 没有真的装第三方插件、没改你的 `cordis.patch.yml`。原因：这两件事都会**永久影响所有会话**，且需要 `danger-full-access` 批准。我把 staging 副本放在 `evidence/cordis.patch.copy.yml`，你要动的话我们先单独聊一次。
