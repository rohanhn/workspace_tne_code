# Environment guard

Mọi câu trả lời liên quan deploy, log, hotfix, restart, MR môi trường phải **dòng đầu**:

`ENV: DEV | STAG | PROD | UNKNOWN` — kèm namespace K8s, platform project, ArgoCD app nếu biết.

- User không nói môi trường → `ENV: UNKNOWN`, **hỏi ENV**. Vẫn được GET overview / `argocd_get_app*` / metrics / GitLab đọc (rule `01`). **Không** kết luận root-cause, **không** đề xuất sửa code/hotfix, **không** restart/`request_log_access` cho đến khi biết ENV. Không mặc định PROD.
- **Đề xuất sửa code** (patch, hotfix, plan implement, diff): **chỉ khi user yêu cầu tường minh**. Mặc định trace/QA/overview: bằng chứng + khoanh vùng; không tự viết cách sửa.
- Map: `dev` / `*-dev` / local = **DEV**. `staging` / `stag` / `uat` / `*-staging` = **STAG**. `prod` / `production` / `*-prod` = **PROD**.
- Nguồn sự thật: `catalog/environments.yaml`.
- PROD: chỉ đọc. **Cấm tuyệt đối** restart (`mcp__platform-system__request_restart_app_deployment` / `execute_restart_app_deployment`), kể cả khi user confirm hoặc có approval URL. Cấm sync, merge, push GitOps, đổi image tag. Hook `.claude/hooks/prod-guard.ps1` chặn thêm ở tầng harness.
- Cảnh báo: app có thể namespace `*-dev` nhưng image tag `staging-*` (đã thấy ở hoc-thi-2).
