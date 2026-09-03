# Agent instructions (TNE orchestration)

Đọc `catalog/` trước khi thao tác đa sản phẩm. Mọi câu trả lời ops phải mở đầu: `ENV: DEV | STAG | PROD | UNKNOWN`.

## MCP

- Ưu tiên **platform-system** (ArgoCD, overview, logs sau grant).
- **gitlab-tne**: chỉ dùng khi `health_check` authenticated. Token dán vào `.cursor/mcp.json` (gitignored) — không log PAT.
- Cấm merge MR, restart PROD, sửa GitOps trừ khi user confirm tường minh từng hành động.

## Skills

- `trace-prod-incident` — lỗi / support
- `qa-env-compare` — lệch DEV vs STAG
- `code-review-mr` — review MR (mặc định không post comment)
- `monitor-team` — snapshot MR / pipeline / board
- `dev-feature` — feature trên clone local

Chi tiết PAT và test kết nối: `references/gitlab-mcp-setup.md`.
