---
description: 本次实操真实撞到的 8 个坑与处理方式。
---

# 踩坑记录

| # | 坑 | 现象 | 处理 |
|---|---|---|---|
| 1 | WMI/CIM 被沙箱拒 | `Get-CimInstance Win32_OperatingSystem` → `拒绝访问` | 改用 `[System.Environment]::OSVersion`、环境变量；硬件信息在 workspace-write 下拿不到 |
| 2 | 版本号双轨 | `ProductVersion=0.2.2.0`，`FileVersion=0.2.2-rc.1` | 报 bug / 写文档统一用 FileVersion |
| 3 | `pwsh` 其实是 5.1 | 名字叫 pwsh，`$PSVersionTable` 是 5.1.26100 | 别用 `??`、三元、`-Parallel` 等 7.x 语法 |
| 4 | `ConvertTo-Json` 把 966 字节 YAML 序列化成 47MB 并卡死 | 反复写出 99MB 的 JSON，管道挂 120s 转后台 | 不用 ConvertTo-Json 处理该字符串；改 `[IO.File]::WriteAllText` + 手拼 JSON |
| 5 | 读 `F:\dfy\resources\app.asar` 被拒 | `[sandbox: file access denied under workspace-write mode]`，Electron 的 asar shim 还顺手把自身源码喷满 stderr | 放弃反编译 asar；`tools/asar-read.mjs` 保留作为思路，未跑通 |
| 6 | B 站网页有验证码 | `web_fetch` 拿到的是「验证码_哔哩哔哩」 | 改用 `api.bilibili.com/x/web-interface/view`、`/x/player/v2` 拿结构化数据（含章节） |
| 7 | 子代理会“顺手补事实” | recon 断言「审批被拒」，实际是开启的 | 见[使用入门](03-usage.md)的「复核子代理」一节：结论必须回源核对 |
| 8 | 定时任务不能自己建 | 会话策略要求「只有用户明确要求才创建」 | 本手册只写怎么做，不替你建 |
