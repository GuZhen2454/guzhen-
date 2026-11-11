---
description: 用本机真实文件解释 DSH 的五层结构：插件包、bundle、profile、服务、你能看见的东西。
---

# 技术概念：DSH 的五层结构（视频 0:45–5:07）

![技术概念：DSH 的五层结构（视频 0:45–5:07）](assets/frames/01-concepts.jpg)

视频这一章讲「DSH 是什么、为什么它长得像乐高」。用你这台机器的真实文件来串，比抽象讲解好懂：

```
① 插件包 (plugin package)      @deepseek-ai/dsh-tool-fs、dsh-skill、dsh-subagent …
        │  被组合进
② Bundle                       dsh-base、dsh-web-app  ← profile/package.json 里就这两行
        │  被展开成
③ Profile 的 Loader 条目树     ~/.dsh/profiles/desktop/{cordis.yml, cordis.patch.yml}
        │  Loader 启动时逐条挂载，注册成
④ 运行时 Service               tools / skills / subagents / workflowEngine / sessions / sandbox …
        │  服务再暴露成
⑤ 你能看见的东西               工具（读文件/跑命令/搜网页）、技能包、子代理、工作流、定时任务、UI 面板
```

本机证据（都能自己打开看）：

- `~/.dsh/profiles/desktop/cordis.yml` 只有 **4 行**，内容是一个空数组 `[]` — 说明「本体是空的，一切靠 patch 叠」【实测】
- `~/.dsh/profiles/desktop/cordis.patch.yml` 966 字节，就是你的**唯一改动层**：`id` + `name` + `config` 三段式【实测】
- `~/.dsh/profiles/desktop/package.json` 211 字节，`dsh.profile.bundles` 里只有两个 bundle【实测】
- 插件树 199 条，其中大量是 `absent`（能装没装）和 `inactive`（装了没启用）——「乐高」这个比喻是真的【实测】

> 译成人话：**DSH 本体不带功能，功能全是插件；你改的不是代码，是 `cordis.patch.yml` 里某条插件的 `config`。**
