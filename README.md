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

## Cấu trúc

- `.cursor/rules/` — guard môi trường, confirm trước khi ghi
- `.cursor/skills/` — 5 workflow: trace PROD, dev feature, QA env, review MR, monitor team
- `catalog/` — map sản phẩm ↔ GitLab ↔ Platform/ArgoCD
- `workspaces/` — file `.code-workspace` multi-root
- `references/` — hướng dẫn MCP, group GitLab
