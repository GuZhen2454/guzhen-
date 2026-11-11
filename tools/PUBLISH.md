# 发布这本手册

两条路，任选一条。**先做第 0 步。**

## 0. 先脱敏

`evidence/` 里保留了写书那台机器的真实路径（含用户名）。发布前跑一次：

```powershell
$user = $env:USERPROFILE
Get-ChildItem .\evidence -File | ForEach-Object {
  $t = Get-Content $_.FullName -Raw
  $t = $t -replace [regex]::Escape($user), 'C:\Users\<user>'
  Set-Content $_.FullName $t -NoNewline
}
```

正文页面已经用 `%USERPROFILE%` 替换过，只有 `evidence/` 需要处理。跑完再执行 `.\tools\check-book.ps1`，确认仍是 `OK`。

## A 路线：本机有 git

### 前置检查

```powershell
git --version          # 没输出就是没装：https://git-scm.com/download/win 或 winget install Git.Git
```

### 命令（Windows PowerShell 5.1 请用分号，不要用 `&&`）

PowerShell 5.1 不认 `&&` / `||`（那是 PowerShell 7+ 的语法），所以：

```powershell
cd dsh-lab
git init
git add .
git commit -m "docs: DSH 实操手册（GitBook 版）"
git branch -M main
git remote add origin https://github.com/<你的账号>/<仓库名>.git
git push -u origin main
```

用 Git Bash / bash / PowerShell 7 的话，`&&` 版本才成立：

```bash
cd dsh-lab && git init && git add . \
  && git commit -m "docs: DSH 实操手册（GitBook 版）" \
  && git branch -M main \
  && git remote add origin https://github.com/<你的账号>/<仓库名>.git \
  && git push -u origin main
```

`git push` 需要凭据：HTTPS 用 Personal Access Token（不是账号密码），或配好 SSH key。这一步没法在无人值守的会话里替你完成。

## B 路线：不装 git

适合只想把书挂上 GitBook、不想碰命令行的情况。

1. 解压 `dsh-lab-gitbook.zip`（或在资源管理器里打开 `dsh-lab` 文件夹）。
2. GitHub 网页 → **New repository** → 建一个空仓库（不要勾 README，否则要先 pull）。
3. 仓库页 → **Add file → Upload files** → 把 `dsh-lab` 里的**全部内容**（不是这个文件夹本身）拖进去 → Commit。
   - 网页上传保留目录结构，但要确认 `.gitbook.yaml`、`.gitignore`、`.gitattributes` 这三个**点文件**也进去了；资源管理器默认不显示它们，先开「显示隐藏文件」。
4. 逐个确认：`README.md`、`SUMMARY.md`、`00-preface.md` … `09-appendix.md` 在仓库根目录，`assets/`、`evidence/`、`tools/` 是三个目录。

## 接 GitBook

1. [gitbook.com](https://www.gitbook.com) → **New space** → **Git Sync** → 授权 GitHub → 选刚推上去的仓库与分支。
2. GitBook 读 `.gitbook.yaml` 里的 `root: ./` 与 `structure.readme/summary`：`README.md` 成为首页，`SUMMARY.md` 成为侧边栏。
3. 首次同步后检查三件事：
   - 侧边栏是 4 个 Part / 10 页；
   - 每页顶部的章节封面能显示（图片走 `assets/frames/`）；
   - [附录](09-appendix.md)里的 `evidence/` 链接能点开。
4. GitBook 免费版对公开空间够用；私有空间要付费。

## 如果同步后页面是空的

按顺序排查：

1. `.gitbook.yaml` 是不是被上传时漏掉了（点文件最容易漏）——没有它 GitBook 会去找默认的 `README.md` + `SUMMARY.md`，此时 `root` 是仓库根，通常也能work。
2. `SUMMARY.md` 的链接是不是相对仓库根：本仓库里就是 `00-preface.md` 这种平铺写法，不能写 `docs/00-preface.md`。
3. 分支对不对：GitBook 默认同步 `main`，推到了 `master` 就得在设置里改。
