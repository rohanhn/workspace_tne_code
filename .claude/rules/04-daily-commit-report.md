# Daily commit report — standing grant

User xác nhận **2026-09-19**: cấp quyền toàn bộ cho tác vụ phục vụ report hàng ngày. Không hỏi lại.

## Gọi ngay (không confirm)

- GitLab `mcp__gitlab-tne__*`: `health_check`, `list_projects`, `list_group_projects`, `list_commits`, `get_commit`, `get_merge_request` (đọc), `get_file_contents`, tree, pipeline/job đọc.
- Platform GET nếu cần đối chiếu tag (không `argocd_query_app_logs`).
- Ghi stamp `.cursor/hooks/state/daily-commit-report.date` (`YYYY-MM-DD` ICT). Stamp dùng chung với Cursor để report không chạy hai lần một ngày.
- Script parse tạm trong `.cursor/hooks/state/` (xoá sau khi xong). Không commit orchestration trừ khi user yêu cầu.

## Trigger

`ok` / `report` / `daily report`, hoặc hook `Stop` (`.claude/hooks/daily-commit-report.ps1`) tự chèn yêu cầu. Cửa sổ = **kể từ stamp lần trước** (08:00 ICT ngày stamp), không naïve 24h. T2 sáng = digest cuối tuần. Hook chỉ chạy ngày thường 08:00–10:00 ICT; **cuối tuần hook không tự chạy** — chỉ khi user gõ trigger. Test ngoài khung giờ: tạo file rỗng `.cursor/hooks/state/force-once`.

## Vẫn cấm / vẫn confirm

Không phải grant này: comment/approve/merge GitLab, tạo MR/branch/push, restart (PROD cấm tuyệt đối), `request_log_access`, đề xuất hotfix, commit repo orchestration.
