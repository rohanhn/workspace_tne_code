# Agent instructions (TNE orchestration)

Đọc `catalog/` trước khi thao tác đa sản phẩm. Mọi câu trả lời ops phải mở đầu: `ENV: DEV | STAG | PROD | UNKNOWN`.

## MCP

- Ưu tiên **platform-system** (ArgoCD, overview, metrics). GET/READ MCP gọi ngay, không hỏi (`argocd_query_app_logs` loại trừ). Thiếu ENV vẫn GET overview, không kết luận. Pod logs: confirm rồi mới `request_log_access`.
- **gitlab-tne**: chỉ dùng khi `health_check` authenticated. Token dán vào `.cursor/mcp.json` (gitignored) — không log PAT.
- **Đề xuất sửa code** chỉ khi user yêu cầu tường minh. Cấm merge MR / sửa GitOps trừ khi confirm. **Restart PROD cấm tuyệt đối.**

## Skills

- `trace-prod-incident` — lỗi / support
- `qa-env-compare` — lệch DEV vs STAG
- `code-review-mr` — review MR (mặc định không post comment)
- `monitor-team` — snapshot MR / pipeline / board
- `dev-feature` — feature trên clone local

Chi tiết PAT và test kết nối: `references/gitlab-mcp-setup.md`.
