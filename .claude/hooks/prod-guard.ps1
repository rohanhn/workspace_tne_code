# PreToolUse guard for Platform restart tools (Claude Code).
# Restart PROD is forbidden absolutely (rule 00/01), even with user confirmation.
# Fail closed: deny when the input mentions PROD, cannot be parsed, or shows no DEV/STAG marker.
$ErrorActionPreference = 'Stop'
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Deny([string]$Reason) {
    $out = @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = $Reason
        }
    }
    [Console]::Out.WriteLine(($out | ConvertTo-Json -Compress -Depth 5))
    exit 0
}

try {
    $event = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    Deny 'prod-guard: không đọc được input hook; chặn restart để an toàn.'
}

$tool = [string]$event.tool_name
$inputText = ($event.tool_input | ConvertTo-Json -Compress -Depth 10)
if ($null -eq $inputText) { $inputText = '' }

if ($inputText -match '(?i)(^|[^a-z])prod(uction)?([^a-z]|$)') {
    Deny "prod-guard: $tool nhắm PROD. Restart PROD bị cấm tuyệt đối (rule 00), kể cả khi đã confirm."
}

if ($inputText -notmatch '(?i)(^|[^a-z])(dev|development|stag|staging|uat)([^a-z]|$)') {
    Deny "prod-guard: không xác định được ENV từ tham số của $tool (không thấy dev/staging). Ghi rõ app/namespace DEV hoặc STAG rồi thử lại."
}

# DEV/STAG: let the normal permission flow (ask) handle confirmation.
exit 0
