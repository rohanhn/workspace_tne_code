# Daily TNE commit report — Claude Code Stop hook.
# Fires once per weekday 08:00–10:00 ICT, after the first finished main-agent turn.
# Shares the stamp with the Cursor hook (.cursor/hooks/state) so the report runs once a day across both tools.
# Test outside the window: create an empty file .cursor/hooks/state/force-once
$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { exit 0 }
    $event = $raw | ConvertFrom-Json
} catch {
    exit 0
}

if ([string]$event.hook_event_name -and [string]$event.hook_event_name -ne 'Stop') { exit 0 }
# Already continuing because of a Stop hook: never loop.
if ($event.PSObject.Properties.Name -contains 'stop_hook_active' -and [bool]$event.stop_hook_active) { exit 0 }

$projectDir = $env:CLAUDE_PROJECT_DIR
if ([string]::IsNullOrWhiteSpace($projectDir)) {
    $projectDir = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
}

$stateDir = Join-Path $projectDir '.cursor\hooks\state'
$stampPath = Join-Path $stateDir 'daily-commit-report.date'
$forcePath = Join-Path $stateDir 'force-once'

try {
    if (-not (Test-Path -LiteralPath $stateDir)) {
        New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    }
} catch {
    exit 0
}

$force = Test-Path -LiteralPath $forcePath
if ($force) {
    Remove-Item -LiteralPath $forcePath -Force -ErrorAction SilentlyContinue
}

$now = [DateTime]::UtcNow.AddHours(7)   # ICT
if (-not $force) {
    if ($now.DayOfWeek -eq [DayOfWeek]::Saturday -or $now.DayOfWeek -eq [DayOfWeek]::Sunday) { exit 0 }
    if ($now.Hour -lt 8 -or $now.Hour -ge 10) { exit 0 }
}

$today = $now.ToString('yyyy-MM-dd')
$previous = $null
try {
    if (Test-Path -LiteralPath $stampPath) {
        $existing = (Get-Content -LiteralPath $stampPath -Raw -ErrorAction SilentlyContinue).Trim()
        if ($existing -eq $today -and -not $force) { exit 0 }
        $parsed = [DateTime]::MinValue
        if ([DateTime]::TryParseExact($existing, 'yyyy-MM-dd', $null, 'None', [ref]$parsed)) {
            $previous = $parsed
        }
    }
    Set-Content -LiteralPath $stampPath -Value $today -Encoding ascii -NoNewline
} catch {
    exit 0
}

# Window = since the previous stamp (08:00 ICT that day); fall back to 24h. Capped at 7 days.
$since = $now.AddHours(-24)
if ($previous -and $previous.Date -lt $now.Date) {
    $since = $previous.Date.AddHours(8)
    if (($now - $since).TotalDays -gt 7) { $since = $now.AddDays(-7) }
}
$sinceLocal = $since.ToString('yyyy-MM-dd HH:mm')
$untilLocal = $now.ToString('yyyy-MM-dd HH:mm')
$sinceUtc = $since.AddHours(-7).ToString('yyyy-MM-ddTHH:mm:ssZ')

$prompt = @"
Follow-up tự động (daily commit report, rule .claude/rules/04-daily-commit-report.md). Chỉ làm đúng việc này. Không hỏi lại. Không sửa code. Không comment/approve/merge GitLab. Không restart hay sync.

Dòng đầu: ENV: DEV | STAG | PROD | UNKNOWN — report này thường phủ cả ba, ghi đủ env có dữ liệu.

Cửa sổ: kể từ stamp lần trước theo ICT ($sinceLocal → $untilLocal, tương đương since=$sinceUtc).

Nhiệm vụ: quét commit GitLab của các sản phẩm catalog verified rồi phân loại theo sản phẩm × môi trường (bảng + tóm tắt).

Cách làm:
1. Đọc catalog/products.yaml, catalog/environments.yaml và catalog/products/*.yaml trước.
2. Dùng GitLab MCP gitlab-tne (mcp__gitlab-tne__*), gọi health_check trước. Không dùng server GitLab nào khác.
3. Liệt kê project theo group tnv, tne5, tnmath, typing-game, bancn, erp, devops (include_subgroups, order last_activity_at). Chỉ lấy repo có last_activity_at trong cửa sổ, rồi list_commits since=$sinceUtc (all=true và theo nhánh env: develop/dev, staging, master/main, tnv/prod, bcn/prod).
4. Map môi trường: nhánh dev/develop/feature → DEV; staging/stag/pre-uat/uat → STAG; master/main/prod/tnv/prod/bcn/prod → PROD. GitOps image-updater: app *-dev-* → DEV, *-staging-* → STAG, *-prod → PROD. Tách commit source vs commit GitOps (đổi image tag). Tag image có thể staging-* dù app ở namespace *-dev (đã thấy ở hoc-thi-2).
5. FE exam-page thuộc V2 Thi, không phải V5. VNMF tách khỏi V5. Platform nội bộ (platform-system) tách mục riêng.
6. Sản phẩm không có commit: một dòng "không có".
7. Tiếng Việt, bảng theo sản phẩm rồi DEV/STAG/PROD; SHA ngắn, message, tác giả, giờ ICT, link. Cuối cùng 3–5 câu tóm tắt.

Nếu GitLab không authenticated: nói rõ (kiểm biến GITLAB_TNE_PAT) và dừng, không đoán.
"@

[Console]::Out.WriteLine((@{ decision = 'block'; reason = $prompt } | ConvertTo-Json -Compress -Depth 4))
exit 0
