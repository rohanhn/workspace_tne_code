# TNE Cursor Orchestration

Repo trung tâm: rules, skills, catalog sản phẩm cho agent Cursor (DevOps / Dev / Review).

GitLab: `https://git.trangnguyen.edu.vn`

## Nhập PAT (bắt buộc trước khi dùng GitLab MCP)

1. Mở [`.cursor/mcp.json`](.cursor/mcp.json) (file local, đã gitignore).
2. Thay `PASTE_GITLAB_PAT_HERE` bằng fine-grained PAT (chỉ Read — xem `references/gitlab-mcp-setup.md`).
3. Lưu file. Cursor reload MCP tự động.
4. Settings → MCP: `gitlab-tne` phải xanh.
5. Chat: “test GitLab MCP: health_check rồi whoami”.

Không dán PAT vào README, catalog, hay tin nhắn chat.

Nếu `~/.cursor/mcp.json` còn server `gitlab-tne` cũ (lẫn `type: http` + `command`), xóa hoặc tắt block đó để tránh hai server trùng tên.

## Dùng với Claude Code

Cấu hình Claude chạy song song với Cursor, dùng chung `catalog/` và `references/`. Xem [`CLAUDE.md`](CLAUDE.md).

1. Đặt hai biến chỉ cho project này trong `.claude/settings.local.json` (đã gitignore), rồi mở lại Claude:
   ```json
   { "env": { "GITLAB_TNE_PAT": "<PAT chỉ Read>", "PLATFORM_MCP_TOKEN": "<token, không kèm Bearer>" } }
   ```
   Biến hệ thống Windows cùng tên cũng dùng được nhưng không cần.
2. Mở repo trong Claude Code, chấp nhận hai server `gitlab-tne` và `platform-system` từ `.mcp.json`, và duyệt hook trong `.claude/settings.json`.
3. Chat: “test GitLab MCP: health_check rồi whoami”.

Token không bao giờ nằm trong `.mcp.json`; file này commit được.

## Cấu trúc

- `.cursor/rules/` — guard môi trường, confirm trước khi ghi
- `.cursor/skills/` — 5 workflow: trace PROD, dev feature, QA env, review MR, monitor team
- `catalog/` — map sản phẩm ↔ GitLab ↔ Platform/ArgoCD
- `workspaces/` — file `.code-workspace` multi-root
- `references/` — hướng dẫn MCP, group GitLab
- `CLAUDE.md`, `.claude/` (rules, skills, hooks, settings), `.mcp.json` — bản tương đương cho Claude Code
