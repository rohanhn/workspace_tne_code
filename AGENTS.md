# Agent instructions (TNE orchestration)

Đọc `catalog/` trước khi thao tác đa sản phẩm. Mọi câu trả lời ops phải mở đầu: `ENV: DEV | STAG | PROD | UNKNOWN`.

## MCP

- Ưu tiên **platform-system** (ArgoCD, overview, metrics). GET/READ MCP gọi ngay, không hỏi (`argocd_query_app_logs` loại trừ). Thiếu ENV vẫn GET overview, không kết luận. Pod logs: confirm rồi mới `request_log_access`.
- **gitlab-tne**: chỉ dùng khi `health_check` authenticated. **`health_check` và `list_projects` gọi ngay, không hỏi** (không thuộc confirm-before-write). Token dán vào `.cursor/mcp.json` (gitignored) — không log PAT.
- **Đề xuất sửa code** chỉ khi user yêu cầu tường minh. Cấm merge MR / sửa GitOps trừ khi confirm. **Restart PROD cấm tuyệt đối.**
- **Daily report:** standing grant (2026-09-19) — GitLab đọc + stamp local, không hỏi. Chi tiết `.cursor/rules/04-daily-commit-report.mdc`. Không gồm write GitLab / restart / log pod.

## Skills

- `trace-prod-incident` — lỗi / support
- `qa-env-compare` — lệch DEV vs STAG
- `code-review-mr` — review MR (mặc định không post comment)
- `monitor-team` — snapshot MR / pipeline / board
- `dev-feature` — feature trên clone local

Chi tiết PAT và test kết nối: `references/gitlab-mcp-setup.md`.
