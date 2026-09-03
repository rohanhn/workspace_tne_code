---
name: trace-prod-incident
description: Traces production/support incidents across TNE products using Platform ArgoCD and optional GitLab MCP. Use when the user reports a PROD/STAG bug, CS ticket, hotfix, outage, or asks to trace an error.
---

# Trace PROD / support incident

## Quick start

1. Read `catalog/products.yaml` and the matching `catalog/products/<slug>.yaml`, plus `references/systems-overview.md` + `references/naming-and-gotchas.md`.
2. First line of every reply: `ENV: DEV | STAG | PROD | UNKNOWN`.
3. If ENV unknown, stop and ask. Do not default to PROD.

## Workflow

1. **Đọc `tnv-troubleshoot-helper` TRƯỚC** (GitLab MCP ws, repo `devops/tnv/tnv-troubleshoot-helper`): `systems/<hệ>/OVERVIEW.md` theo đường traffic domain → LB → service → infra, `notes/<hệ>.md`, `runbooks/`. Đây là bản đồ vận hành sống — ưu tiên hơn giả định.
2. Identify product + likely ArgoCD `appName` from catalog (chú ý mapping tên lệch app↔repo trong `naming-and-gotchas.md`).
3. `platform_get_project_overview(projectId)` for that env.
4. `argocd_get_app(appName)` — pods, image tag, Helm values, GitOps path. **Tag thật ở `.argocd-source-*.yaml`, không phải `values.yaml`.**
5. Logs: `request_log_access` once per app → give user the approval URL → after grant, `argocd_query_app_logs`.
6. Correlate image tag / GitOps commit. Inspect source repo/MR qua GitLab MCP ws (`project-0-workspace_tne_code-gitlab-tne-ws`).
7. If local clone is in the workspace, search code. Do not guess missing source paths.

## Heuristics

- **Liên sản phẩm:** lỗi login/user toàn hệ → **KC trung tâm (IAM tne5)** + 2 service `cdc`/`sync` (V5); login riêng cms/quantri → **KC v2** (`tnv/keycloak`); session V2 hỏng → **Redis**; thiếu trường/huyện/tỉnh → REST **V5 master data**.
- **V2 stack:** nghẽn/mất bài khi thi online tải lớn (~500k CCU) → **Kafka** lag + `consumer`/`consumer-sync-data`; task background trễ → **RabbitMQ**; lỗi file/upload → **MinIO**; DB chính = **MongoDB**.
- **Timeout app→app** (tnv/bcn) → check HAProxy `192.168.60.6` map (domain thiếu = silent-drop).
- **PROD v2/bcn** ở repo manifest CŨ (`tnv-argocd-manifest` `tnv/prod`, `bcn-argocd-manifest` `bcn/prod`).

## Forbidden

Restart, sync, merge, push GitOps, change tags. Propose hotfix only.

## Output

Follow [output-template.md](output-template.md).
