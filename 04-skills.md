---
description: 技能包就是一个目录加一个 SKILL.md：规范、三条铁律，以及自定义技能目录放在哪。
---

# 技能包：最容易被低估的一层

视频「使用教程」里专门讲了技能包。本机的技能不是代码，就是**目录 + 一个 SKILL.md**：

```
office-skills/
├── office/SKILL.md              ← 纯路由：只做分诊，不含代码
├── office-docx/SKILL.md
├── office-xlsx/SKILL.md
└── office-render/SKILL.md
```

**最小可用 SKILL.md**（本机 7 个技能全部是这个结构）【实测】：

```markdown
---
name: office            # 必填，小写连字符，必须等于目录名
description: Create, edit, inspect, or convert Office documents...  # 必填，一行触发句
---

# Office task routing          ← H1：人读的标题

正文用祈使句写给模型看：
- 什么情况下加载我（正向触发）
- 什么情况下**不要**加载我（负向触发，最容易被漏掉）
- 具体怎么做（最小可运行代码）
- 做完怎么交付
```

三条写作铁律，直接决定技能好不好用：

1. **`description` 是唯一的预告片**：模型平时只看到这一行摘要，命中才读正文。所以它必须同时回答「能做什么」和「什么任务该加载我」，不能写成宣传语。
2. **必须写负向触发**。本机 `office-render` 就明确规定：粗体表头、数字格式这类附带格式化**不要**触发渲染。没有这句话，模型会把简单任务做成十步流水线。
3. **按需加载，不要塞进系统提示**。七个技能正文全塞进系统提示，既费 token 又互相打架（「普通编辑不必渲染」和「外观改动必须渲染」分处两个技能才各自成立）。

## 顺带解开的一个谜：自定义技能包放哪

上面说过，技能就是「目录 + SKILL.md」，但没说目录到底在哪。答案在预设第 124–128 行：

```yaml
- id: skill-filesystem
  name: '@deepseek-ai/dsh-skill-filesystem'
  config:
    customSkillDirs:
      - !!js ... resolve('@deepseek-ai/dsh-agent-preset/package.json') ... /skills
```

`skill-filesystem` 扫的就是 `customSkillDirs` 这几个目录（本机指向 dsh 安装目录里的 `dsh-agent-preset/skills`，所以 `cordis-*`、`office-*` 那堆技能都在）。**想加自己的技能包：把这个配置项指到你自己的目录，再往里放 `<name>/SKILL.md`。** 同样走 bundle + install_bundle，别手改预设文件。
