# Daily TNE commit report (local hook — Cloud Automations cannot use workspace GitLab).
# Fires once per weekday 08:00–10:00 local time after the first completed Agent turn.
# Test outside the window: create an empty file .cursor/hooks/state/force-once
$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Write-HookJson([hashtable]$Object) {
    $json = $Object | ConvertTo-Json -Compress -Depth 6
    [Console]::Out.WriteLine($json)
}

$empty = @{}
try {
    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) {
        Write-HookJson $empty
        exit 0
    }
    $event = $raw | ConvertFrom-Json
} catch {
    Write-HookJson $empty
    exit 0
}

$eventName = [string]$event.hook_event_name
if ($eventName -and $eventName -ne 'stop') {
    Write-HookJson $empty
    exit 0
}

if ([string]$event.status -ne 'completed') {
    Write-HookJson $empty
    exit 0
}

if ($event.PSObject.Properties.Name -contains 'is_background_agent' -and [bool]$event.is_background_agent) {
    Write-HookJson $empty
    exit 0
}

$mode = [string]$event.composer_mode
if ($mode -and $mode -ne 'agent') {
    Write-HookJson $empty
    exit 0
}

$loopCount = 0
if ($event.PSObject.Properties.Name -contains 'loop_count') {
    $loopCount = [int]$event.loop_count
}
if ($loopCount -gt 0) {
    Write-HookJson $empty
    exit 0
}

$projectDir = $env:CURSOR_PROJECT_DIR
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
    Write-HookJson $empty
    exit 0
}

$force = Test-Path -LiteralPath $forcePath
if ($force) {
    Remove-Item -LiteralPath $forcePath -Force -ErrorAction SilentlyContinue
}

$now = [DateTime]::UtcNow.AddHours(7)
if (-not $force) {
    if ($now.DayOfWeek -eq [DayOfWeek]::Saturday -or $now.DayOfWeek -eq [DayOfWeek]::Sunday) {
        Write-HookJson $empty
        exit 0
    }
    if ($now.Hour -lt 8 -or $now.Hour -ge 10) {
        Write-HookJson $empty
        exit 0
    }
}

$today = $now.ToString('yyyy-MM-dd')
try {
    if (Test-Path -LiteralPath $stampPath) {
        $existing = (Get-Content -LiteralPath $stampPath -Raw -ErrorAction SilentlyContinue).Trim()
        if ($existing -eq $today) {
            Write-HookJson $empty
            exit 0
        }
    }
    Set-Content -LiteralPath $stampPath -Value $today -Encoding ascii -NoNewline
} catch {
    Write-HookJson $empty
    exit 0
}

$sinceLocal = $now.AddHours(-24).ToString('yyyy-MM-dd HH:mm')
$untilLocal = $now.ToString('yyyy-MM-dd HH:mm')
$sinceUtc = $now.ToUniversalTime().AddHours(-24).ToString("yyyy-MM-ddTHH:mm:ssZ")

$prompt = @"
Đây là follow-up tự động (daily commit report). Chỉ làm đúng việc này. Không hỏi lại. Không sửa code. Không comment/approve/merge GitLab. Không restart hay sync.

Dòng đầu: ENV: DEV | STAG | PROD | UNKNOWN — report này thường phủ cả ba, ghi đủ env có dữ liệu.

Cửa sổ: 24 giờ vừa rồi theo ICT ($sinceLocal → $untilLocal, tương đương since=$sinceUtc).

Nhiệm vụ: quét commit GitLab của 6 sản phẩm catalog verified rồi phân loại theo sản phẩm × môi trường, cùng format lần review thủ công (bảng + tóm tắt).

Cách làm:
1. Đọc catalog/products.yaml, catalog/environments.yaml và catalog/products/*.yaml trước.
2. Dùng GitLab MCP workspace của project này (đã health_check authenticated). Không dùng GitLab user-level (token cũ, 403 giả). Không dùng Platform GitLab nếu unauthenticated.
3. Liệt kê project theo group tnv, tne5, tnmath, typing-game, bancn, erp, devops (include_subgroups, order last_activity_at). Chỉ lấy repo có last_activity_at trong 24h, rồi list_commits since=$sinceUtc (all=true và theo nhánh env: develop/dev, staging, master/main, tnv/prod, tnv/dev).
4. Map môi trường: nhánh dev/develop/feature → DEV; staging/stag/pre-uat/uat → STAG; master/main/prod/tnv/prod/bcn/prod → PROD. GitOps image-updater: app *-dev-* → DEV, *-staging-* → STAG, *-prod → PROD. Tách commit source vs commit GitOps (đổi image tag). Tag image có thể staging-* dù app đang namespace *-dev (đã thấy ở hoc-thi-2).
5. FE exam-page thuộc V2 Thi, không phải V5. Platform nội bộ (platform-system) tách mục riêng.
6. Sản phẩm không có commit: một dòng "không có".
7. Tiếng Việt, bảng theo sản phẩm rồi DEV/STAG/PROD; SHA ngắn, message, tác giả, giờ ICT, link. Cuối cùng 3–5 câu tóm tắt.

Nếu GitLab không authenticated: nói rõ và dừng, không đoán.
"@

Write-HookJson @{ followup_message = $prompt }
exit 0
