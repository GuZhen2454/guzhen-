# build-book.ps1 — split the single-file manual into a GitBook-shaped tree.
# Windows PowerShell 5.1, no external deps. Safe to re-run.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = 'C:\Users\guzhen\Documents\deepseek-harness\default-workspace\dsh-lab'
$Src  = Join-Path $Root 'DSH-实操手册.md'
$Utf8 = [Text.UTF8Encoding]::new($false)

# ---- 1. evidence/ + frame renames (idempotent) -----------------------------
$ev = Join-Path $Root 'evidence'
New-Item -ItemType Directory -Force -Path $ev | Out-Null
$oldOut = Join-Path $Root 'out'
if (Test-Path $oldOut) {
  Get-ChildItem $oldOut -File | ForEach-Object { Move-Item $_.FullName (Join-Path $ev $_.Name) -Force }
  Remove-Item $oldOut -Force -Recurse
}

$frameMap = @(
  @('0-导入.jpg',       '00-intro.jpg'),
  @('45-技术概念.jpg',  '01-concepts.jpg'),
  @('307-安装配置.jpg', '02-install.jpg'),
  @('793-使用教程.jpg', '03-usage.jpg'),
  @('1850-插件实战.jpg','04-plugins.jpg'),
  @('2838-总结.jpg',    '05-summary.jpg')
)
$fr = Join-Path $Root 'assets\frames'
foreach ($pair in $frameMap) {
  $from = Join-Path $fr $pair[0]
  if (Test-Path $from) { Move-Item $from (Join-Path $fr $pair[1]) -Force }
}

# ---- 2. slice by heading ---------------------------------------------------
$all = [IO.File]::ReadAllLines($Src)

function Find-Heading([string]$prefix) {
  for ($i = 0; $i -lt $all.Count; $i++) {
    if ($all[$i].StartsWith($prefix)) { return $i }
  }
  throw "heading not found: $prefix"
}

$iCheck   = Find-Heading '## 0. 本机体检'
$iConc    = Find-Heading '## 1. 技术概念'
$iInst    = Find-Heading '## 2. 安装与首次运行'
$iUsage   = Find-Heading '## 3. 使用入门'
$iSkill   = Find-Heading '### 3.1 技能包'
$iSub     = Find-Heading '### 3.2 子代理'
$iPlug    = Find-Heading '## 4. 插件实战'
$iPit     = Find-Heading '## 5. 踩坑记录'
$iCheat   = Find-Heading '## 6. 速查表'
$iSwitch  = Find-Heading '## 7. 功能到底开没开'
$iSkill76 = Find-Heading '### 7.6 顺带解开的一个谜'
$iLesson  = Find-Heading '### 7.7 这一节的教训'

# Returns a plain string[] (never a single unwrapped string).
function Slice([int]$from, [int]$toExclusive) {
  $out = New-Object System.Collections.Generic.List[string]
  if ($toExclusive -gt $from) {
    for ($i = $from; $i -lt $toExclusive; $i++) { $out.Add($all[$i]) }
  }
  return $out.ToArray()
}

# Strip leading section numbers from headings; drop horizontal rules.
function Normalize([string[]]$content) {
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($line in $content) {
    if ($line.Trim() -eq '---') { continue }
    if ($line -match '^(#{2,3}) \d+(?:\.\d+)*\.? (.+)$') { $out.Add("$($Matches[1]) $($Matches[2])") }
    else { $out.Add($line) }
  }
  return $out.ToArray()
}

function Trim-Edges([string[]]$lines) {
  $b = New-Object System.Collections.Generic.List[string]
  foreach ($l in $lines) { $b.Add($l) }
  while ($b.Count -gt 0 -and $b[0].Trim() -eq '') { $b.RemoveAt(0) }
  while ($b.Count -gt 0 -and $b[$b.Count - 1].Trim() -eq '') { $b.RemoveAt($b.Count - 1) }
  return $b.ToArray()
}

function Page([string]$file, [string]$h1, [string]$desc, [string[]]$content, [string]$image, [switch]$KeepFirst) {
  $body = Trim-Edges (Normalize $content)
  if (-not $KeepFirst -and $body.Count -gt 0 -and ($body[0].StartsWith('## ') -or $body[0].StartsWith('### '))) {
    $body = @($body | Select-Object -Skip 1)
    $body = Trim-Edges $body
  }

  # Pages whose body has no ## section (the old ## heading became the page H1)
  # get their headings promoted one level so the outline stays a tree.
  $hasH2 = $false
  foreach ($l in $body) { if ($l.StartsWith('## ')) { $hasH2 = $true; break } }
  if (-not $hasH2) {
    $body = @($body | ForEach-Object {
      if ($_ -match '^#### (.+)$') { "### $($Matches[1])" }
      elseif ($_ -match '^### (.+)$') { "## $($Matches[1])" }
      else { $_ }
    })
  }

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add('---'); $lines.Add("description: $desc"); $lines.Add('---'); $lines.Add('')
  $lines.Add("# $h1"); $lines.Add('')
  if ($image) { $lines.Add("![$h1]($image)"); $lines.Add('') }
  foreach ($l in $body) { $lines.Add($l) }

  $path = Join-Path $Root $file
  $t = ($lines -join "`n")
  while ($t.Contains("`n`n`n")) { $t = $t.Replace("`n`n`n", "`n`n") }
  $t = $t.Replace('](out/', '](evidence/')
  $t = $t.Replace('`out/', '`evidence/')
  $t = $t.Replace('\out\', '\evidence\')
  $t = $t.Replace('C:\Users\guzhen', '%USERPROFILE%')
  $t = $t.Replace('[§7](#7-功能到底开没开三层开关的真相)', '[功能开关](06-switches.md)')
  [IO.File]::WriteAllText($path, $t + "`n", $Utf8)
}

$b1 = @(); $b1 += Slice $iConc $iInst
Page '01-concepts.md' '技术概念：DSH 的五层结构（视频 0:45–5:07）' `
  '用本机真实文件解释 DSH 的五层结构：插件包、bundle、profile、服务、你能看见的东西。' `
  $b1 'assets/frames/01-concepts.jpg'

$b2 = @(); $b2 += Slice $iCheck $iConc; $b2 += Slice $iInst $iUsage
Page '02-install.md' '体检与安装（视频 5:07–13:13）' `
  '本机安装形态、首次启动生成物，以及三个真正值得改的配置项。' `
  $b2 'assets/frames/02-install.jpg' -KeepFirst

$b3 = @(); $b3 += Slice $iUsage $iSkill; $b3 += Slice $iSub $iPlug
Page '03-usage.md' '使用入门：让 SuperAgent 真干活（视频 13:13–30:50）' `
  '说一句话，DSH 调什么：工具、待办、目标、子代理、工作流、后台任务与定时任务。' `
  $b3 'assets/frames/03-usage.jpg'

$b4 = @(); $b4 += Slice $iSkill $iSub; $b4 += Slice $iSkill76 $iLesson
Page '04-skills.md' '技能包：最容易被低估的一层' `
  '技能包就是一个目录加一个 SKILL.md：规范、三条铁律，以及自定义技能目录放在哪。' `
  $b4 $null

$b5 = @(); $b5 += Slice $iPlug $iPit
Page '05-plugins.md' '插件实战：改 config 而不是改代码（视频 30:50–47:18）' `
  'Inspect Provider 怎么读插件树、patch 层的三种写法与三条坑、加能力的四条路。' `
  $b5 'assets/frames/04-plugins.jpg'

$b6 = @(); $b6 += Slice $iSwitch $iSkill76; $b6 += Slice $iLesson $all.Count
Page '06-switches.md' '功能到底开没开：三层开关的真相' `
  '为什么 enabled: false 的功能还能用：profile、预设、客户端三层开关，以及怎么真的开一个能力。' `
  $b6 $null

$b7 = @(); $b7 += Slice $iPit $iCheat
Page '07-pitfalls.md' '踩坑记录' `
  '本次实操真实撞到的 8 个坑与处理方式。' `
  $b7 $null

$b8 = @(); $b8 += Slice $iCheat $iSwitch
Page '08-cheatsheet.md' '速查表' `
  '只读体检命令与「想干的事 → 就这么说」对照表。' `
  $b8 $null

# ---- 3. report -------------------------------------------------------------
Get-ChildItem $Root -Filter '*.md' | Sort-Object Name | ForEach-Object {
  $l = [IO.File]::ReadAllLines($_.FullName)
  '{0,-22} {1,4} lines {2,7} bytes' -f $_.Name, $l.Count, $_.Length
}
