# Claude Code — TNE orchestration

Repo này dùng chung cho Cursor (`.cursor/`) và Claude Code (`.claude/`, `.mcp.json`).
`AGENTS.md` là bản tóm tắt chung; luật chi tiết cho Claude nằm ở `.claude/rules/`
và được nạp tự động. `catalog/` và `references/` dùng chung, không nhân bản.

## Ánh xạ Cursor → Claude

| Cursor | Claude Code |
|---|---|
| `.cursor/rules/*.mdc` | `.claude/rules/*.md` |
| `.cursor/skills/*` | `.claude/skills/*` (gọi bằng `/<tên-skill>`) |
| `.cursor/mcp.json` (PAT dán vào file) | `.mcp.json` (PAT lấy từ biến môi trường) |
| `.cursor/hooks.json` | `.claude/settings.json` → `hooks` |
| server `project-0-workspace_tne_code-gitlab-tne-ws` | server `gitlab-tne` → tool `mcp__gitlab-tne__*` |
| server `platform-system` | server `platform-system` → tool `mcp__platform-system__*` |
| subagent Bugbot / `review-security` | `/code-review`, `/security-review` |

Khi `references/` hoặc `catalog/` nhắc tên server Cursor (`...-gitlab-tne-ws`), hiểu là `gitlab-tne`.

## Bảo vệ được cưỡng chế (không chỉ là lời nhắc)

`.claude/settings.json`:
- Tool đọc GitLab/Platform: cho phép sẵn.
- `argocd_query_app_logs`, `request_log_access`, restart DEV/STAG: luôn hỏi.
- Tool ghi GitLab (merge/approve/comment/push/tạo branch, MR): bị chặn.
- Hook `prod-guard.ps1`: chặn mọi lệnh restart có dấu hiệu PROD, kể cả khi đã được cho phép.

## Biến môi trường cần có

Đặt trong `.claude/settings.local.json` → `env` (chỉ project này, gitignore). Claude bị chặn đọc `.cursor/mcp.json` nên không tự copy token; user tự điền.

Server `gitlab-tne` (stdio) chạy qua `.claude/mcp/gitlab-launch.js`: Claude không thay `${...}` từ `settings.local.json` vào env của server stdio, nên launcher tự đọc `GITLAB_TNE_PAT` từ file đó. Server HTTP `platform-system` thì `${PLATFORM_MCP_TOKEN}` trong header vẫn được thay bình thường.

- `GITLAB_TNE_PAT` — fine-grained PAT chỉ Read (xem `references/gitlab-mcp-setup.md`).
- `PLATFORM_MCP_TOKEN` — token Platform MCP (không gồm tiền tố `Bearer `).

Không in giá trị hai biến này ra chat, log hay file commit.
