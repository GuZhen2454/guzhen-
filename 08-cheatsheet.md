---
description: 只读体检命令与「想干的事 → 就这么说」对照表。
---

# 速查表

**只读体检命令（可直接粘贴）**

```powershell
# 版本与渠道
Get-Item 'F:\dfy\DeepSeek Harness.exe' | ForEach-Object { $_.VersionInfo.FileVersion, $_.VersionInfo.ProductVersion }
Get-Content 'F:\dfy\resources\app-update.yml'

# profile 结构
Get-ChildItem "$env:DSH_PROFILE_DIR" -Force | Select-Object Name,Length
Get-Content "$env:DSH_PROFILE_DIR\cordis.patch.yml"

# 模型与预设（当前生效值）
Select-String -Path "$env:DSH_PROFILE_DIR\cordis.patch.yml" -Pattern 'model:|reasoningEffort|selectedDefault'

# 内置技能包
Get-ChildItem 'F:\dfy\resources\runtime\office-skills' -Directory | ForEach-Object Name

# 用户数据全景
Get-ChildItem "$env:DSH_HOME" -Force | Select-Object Name
```

**DSH 里的高频说法 → 动作**

| 想干的事 | 就这么说 |
|---|---|
| 摸清环境 | 「只做只读检查，列出……，每条注明来源，不确定的写未验证」 |
| 干净地调研 | 「这个你去查，只要结论和链接，别把过程带回来」 |
| 批量活 | 「用 workflow 并行处理这 20 个文件，每个返回 JSON」 |
| 长任务 | 「建个目标盯着做完，中途卡住告诉我」 |
| 要复用 | 「把刚才这套沉淀成技能包，写 SKILL.md」 |
