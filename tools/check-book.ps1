# check-book.ps1 - structural checks for the GitBook tree in this directory.
# Windows PowerShell 5.1, no dependencies. Exit 0 = clean, 1 = errors found.
#
# Checks
#   1. every SUMMARY.md target exists
#   2. every root .md is either in SUMMARY.md or an allowed orphan
#   3. every relative link/image resolves; no '#anchor' links; no non-ASCII targets
#   4. every page has YAML front matter with description: and an H1
#   5. no machine-specific user paths on published pages (evidence/ warns only)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$AllowedOrphans = @('README.md', 'SUMMARY.md')   # plus any 'DSH-*' legacy stub

$errors   = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]
$enc      = [Text.UTF8Encoding]::new($false)

function Read-Text([string]$path) { return [IO.File]::ReadAllText($path, $enc) }

# ---- 1 + 2. SUMMARY coverage ----------------------------------------------
$summaryPath = Join-Path $Root 'SUMMARY.md'
if (-not (Test-Path $summaryPath)) { $errors.Add('SUMMARY.md is missing'); }
$summary = @()
if (Test-Path $summaryPath) {
  $text = Read-Text $summaryPath
  foreach ($m in [regex]::Matches($text, '\]\(([^)]+\.md)\)')) {
    $target = $m.Groups[1].Value
    $summary += $target
    if (-not (Test-Path (Join-Path $Root $target))) { $errors.Add("SUMMARY.md points at a missing file: $target") }
  }
}

$pages = Get-ChildItem $Root -Filter '*.md' -File | ForEach-Object { $_.Name } | Sort-Object
foreach ($page in $pages) {
  if ($AllowedOrphans -contains $page) { continue }
  if ($page -like 'DSH-*') { continue }
  if ($summary -notcontains $page) { $errors.Add("orphan page (not listed in SUMMARY.md): $page") }
}
foreach ($s in $summary) {
  if ($pages -notcontains $s) { $errors.Add("SUMMARY.md lists a file that is not in the root: $s") }
}

# ---- 3 + 4 + 5. per-page checks -------------------------------------------
$rows = @()
foreach ($page in $pages) {
  $path = Join-Path $Root $page
  $text = Read-Text $path
  $lines = $text -split "`n"
  $pageErrors = 0

  # front matter + H1
  $hasFront = ($lines.Count -gt 0 -and $lines[0].Trim() -eq '---')
  $hasDesc  = ($text -match '(?m)^description:\s*\S')
  $hasH1    = ($text -match '(?m)^# \S')
  if ($page -notlike 'DSH-*' -and $page -ne 'SUMMARY.md') {
    if (-not $hasFront) { $errors.Add("${page}: no YAML front matter"); $pageErrors++ }
    if (-not $hasDesc)  { $errors.Add("${page}: front matter has no description:"); $pageErrors++ }
  }
  if (-not $hasH1)    { $errors.Add("${page}: no H1 heading"); $pageErrors++ }

  # links and images
  $linkCount = 0
  foreach ($m in [regex]::Matches($text, '\]\(([^)]+)\)')) {
    $target = $m.Groups[1].Value
    if ($target -match '^(https?:|mailto:|#)') {
      if ($target.StartsWith('#')) { $errors.Add("${page}: in-page anchor link not allowed: $target"); $pageErrors++ }
      continue
    }
    $linkCount++
    if ($target -match '[^\x20-\x7E]') { $errors.Add("${page}: non-ASCII link target: $target"); $pageErrors++ }
    $clean = ($target -split '#')[0]
    if ($clean -eq '') { continue }
    $resolved = Join-Path $Root $clean
    if (-not (Test-Path $resolved)) { $errors.Add("${page}: broken link -> $target"); $pageErrors++ }
  }

  # machine-specific paths (C:\Users\<user> placeholders are fine)
  $userHits = ([regex]::Matches($text, [regex]::Escape('C:\Users\') + '(?!<)')).Count
  if ($userHits -gt 0) {
    if ($page -notlike 'DSH-*') { $errors.Add("${page}: $userHits absolute user path(s) left in a published page"); $pageErrors++ }
  }

  $h2 = ([regex]::Matches($text, '(?m)^## \S')).Count
  $rows += [pscustomobject]@{ Page = $page; Lines = $lines.Count; H2 = $h2; Links = $linkCount; Errors = $pageErrors }
}

# evidence/ may keep real paths, but say so once
$ev = Join-Path $Root 'evidence'
if (Test-Path $ev) {
  $hit = 0
  Get-ChildItem $ev -File | ForEach-Object {
    $hit += ([regex]::Matches((Read-Text $_.FullName), [regex]::Escape('C:\Users\'))).Count
  }
  if ($hit -gt 0) { $warnings.Add("evidence/ keeps $hit real path(s); scrub before publishing (see 09-appendix.md)") }
}

# ---- report ---------------------------------------------------------------
$rows | Format-Table -AutoSize | Out-String | Write-Host

Write-Host ("pages: {0}   summary entries: {1}   errors: {2}   warnings: {3}" -f $rows.Count, $summary.Count, $errors.Count, $warnings.Count)
foreach ($w in $warnings) { Write-Host "WARN  $w" }
foreach ($e in $errors)   { Write-Host "ERROR $e" }

if ($errors.Count -gt 0) { exit 1 }
Write-Host 'OK - book structure is clean.'
exit 0
