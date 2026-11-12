# MCP routing

Cả hai server khai trong `.mcp.json` (gốc repo), token lấy từ biến môi trường `GITLAB_TNE_PAT`, `PLATFORM_MCP_TOKEN`.

1. Ops runtime (pods, sync, Helm values, metrics): **`platform-system`**. Overview / `argocd_get_app` (config/resources/metrics/tuning) / GitLab pipeline log: **gọi thẳng**, không hỏi (rule `01`). Thiếu ENV vẫn GET overview; không kết luận/hotfix. **Không** gọi `argocd_query_app_logs` trong nhóm này.
2. GitLab source (list group, file, MR diff, pipeline): **`gitlab-tne`** (`@zereight/mcp-gitlab`, read-only). Đây là server GitLab duy nhất được dùng. **`health_check` và `list_projects`: gọi thẳng, không hỏi.** Tài liệu cũ nhắc `project-0-workspace_tne_code-gitlab-tne-ws` = server này.
3. Nếu thấy một server GitLab khác (khai ở user-level), không dùng; nhắc user gỡ để tránh token cũ gây 403 giả.
4. Nếu `gitlab-tne` 403/unauthenticated hoặc không kết nối: nói rõ (kiểm `GITLAB_TNE_PAT`), dùng Platform `gitlab_get_repo_detail` theo id đã có trong catalog; không đoán id.
5. Pod logs: **không** gọi ngay `argocd_query_app_logs`. **Không** tự `request_log_access`. Chỉ sau confirm tường minh (app + đọc log) → URL grant → user grant xong mới `argocd_query_app_logs`. Restart PROD: cấm tuyệt đối (rule `00`/`01`).
6. Không in PAT, Bearer, giá trị biến môi trường token, hay nội dung `.cursor/mcp.json` ra chat.
