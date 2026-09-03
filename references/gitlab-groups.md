# GitLab groups — map thật

Nguồn: `list_namespaces` / `list_projects` qua server workspace `project-0-workspace_tne_code-gitlab-tne-ws`
(GitLab 19.2.4-ee, host `https://git.trangnguyen.edu.vn`). Recheck: xem lại bằng `list_namespaces` nếu nghi lỗi thời.

## Groups sản phẩm (nguồn code)

| Group | ID | full_path | Sản phẩm | Ghi chú |
|---|---|---|---|---|
| tnv | 4 | `tnv` | **V2 / Thi** | 48 projects. `tnv/keycloak` (KC v2 cũ). |
| tne5 | 143 | `tne5` | **V5 / Học** | 12 projects. Subgroups: `frontend` (140), `backend` (180), `devops` (239), `infra` (157). |
| tne5/frontend | 140 | `tne5/frontend` | FE V2 + V5 | 8 projects: `exam-page` (FE V2), `v5`, `admin-v5`, `v5-identity` (IAM). |
| tne5/backend | 180 | `tne5/backend` | V5 BE | 2 projects: `v5` (monolith Node.js). |
| tnmath | 266 | `tnmath` | **V6 / TNMath** | 16 projects. Mirror từ tinhvan. |
| typing-game | 147 | `typing-game` | **LachCach** | 3 projects: `game-client`, `gameserver`, `cms`. |
| bancn | 59 | `bancn` | **BCN Inhouse** | 19 projects. Subgroups: `crm` (172), `vnmf` (217). Noibo = `support_tnv2*`. |
| erp | 294 | `erp` | BCN CRM2 | `erp/crm-v2` (165). |

## Groups GitOps / DevOps

| Group | ID | full_path | Ghi chú |
|---|---|---|---|
| devops | 151 | `devops` | 41 projects. GitOps manifest cấp cao. |
| devops/tnv | 284 | `devops/tnv` | 14 projects: `tnv-argocd-config` (159), `tne5-argocd-config` (166), `lachcach-argocd-config` (167), `bcn-argocd-config` (164). |
| devops/argocd | 211 | `devops/argocd` | `tnv-argocd-config-prod` (108, mới — chưa dùng). |
| devops/tnmath | 254 | `devops/tnmath` | 11 projects — GitOps V6. |
| tnv/devops | 5 | `tnv/devops` | Repo manifest CŨ: `tnv-argocd-manifest` (PROD `tnv/prod`), `tnv-troubleshoot-helper`. |
| tne5/devops | 239 | `tne5/devops` | `tne5-argocd-manifest` (dev). |

## KC / Identity (2 Keycloak — phân biệt theo HOST)

- KC trung tâm (IAM): `tne5/frontend/v5-identity` (128) — host `iam.dev-v3`, realm `tnv-main`.
- KC v2 (cũ): `tnv/keycloak` (53) — host `iam-dev`, realm `tnv`, cho cms/quantri.

## Ghi chú / cần lưu ý

- `app_danh_may` (125) — group tồn tại nhưng **0 project**; source LachCach thực nằm ở `typing-game` (147).
- `tne6` (193, 9 projects) — group riêng, **không nhầm với V6/tnmath**; chưa thuộc scope 6 sản phẩm, hỏi user nếu cần.
- `crm` (160, top-level, 1 project) — khác `bancn/crm` (172); xác nhận trước khi map.
- `tnv-mobile-web` (112), `games` (91), `shared` (86) — ngoài scope hiện tại.
- Không đoán project id; luôn `get_project` / `list_group_projects` theo path để verify trước khi thao tác.
