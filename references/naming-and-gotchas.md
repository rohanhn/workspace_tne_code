# Naming & gotchas

Trích từ `devops/tnv/tnv-troubleshoot-helper` (CLAUDE.md + systems/*). Đọc trước khi trace/QA/review đa repo.

## Quy ước tên group ↔ sản phẩm

| Group | Sản phẩm | Nguồn | Ghi chú |
|---|---|---|---|
| `tnv` | v2 — Trạng Nguyên Tiếng Việt | outsource → BCN maintain | micro-service |
| `tne5` | v5 — trang chủ `trangnguyen.edu.vn` (HUB) | outsource | monolith BE + FE tách |
| `tnmath` | v6 | outsource (mirror tinhvan) | micro-service |
| `bcn` / `bancn` | in-house (CRM, CRM2, Noibo, Chatbot) | BCN tự phát triển | VNMF = subgroup `bancn/vnmf`, catalog [`vnmf.yaml`](../catalog/products/vnmf.yaml) |
| `typing-game` | lachcach | outsource | `app_danh_may` = group rỗng |

> Outsource = đối tác viết → **BCN maintain sau bàn giao**.

## Image path = repo GitLab
CI dùng `$CI_PROJECT_PATH` → **image registry path = group/repo nguồn**. Nhìn image trong ArgoCD suy ra repo.

## Bảng mapping tên lệch (app ArgoCD ≠ repo GitLab)

| App / image | Repo GitLab thật | Hệ |
|---|---|---|
| `api-cms-service` | `tnv/cms-trang-nguyen-api` | v2 |
| `bcn-cms` | `bancn/cms-admin` (**KHÁC** `tnv/cms-admin`!) | bcn |
| `hoc-thi-2` | `tne5/frontend/exam-page` | v2 (FE) |
| `kafka-connect` | `tnv/kafka-connect-cdc` | v2 |
| `consumer-service` | `tnv/api-payment` (image typo `comsumers`) | v2 (legacy payment) |
| `learning-service` | `tnmath/.../cms-service` | v6 |
| `scorecard-service` | `tnmath/.../scorecard-recommendation` | v6 |
| `math-collab` | `tnmath/.../frontend-collab` | v6 |
| `api` & `cdc` | chung image `tne5/backend/v5` | v5 |

Monorepo: `tnv/tnv2-learn-exam-v2` build nhiều image (`tnv-exam-api`, `tnv-learn-api`, `tnv-student-api`, `tnv-consumer`, `tnv-consumer-sync-data`, `tnv-scheduler`). Xem `catalog/products/v2-thi.yaml`.

## Gotcha 1 — IAM có 2 Keycloak (phân biệt theo HOST)
- **KC trung tâm = tne5** `v5-identity`: host `iam.dev-v3.trangnguyen.edu.vn` (dev) / `id.trangnguyen.edu.vn` (v6 prod), realm `tnv-main`/`tne-main`. STAG không có IAM riêng — V2/V5 staging auth `tne5-dev-iam`.
- **KC v2 (cũ) = tnv** `keycloak` (app `keycloak-cluster`, image tag `prod` ngay ở dev): host `iam-dev`, realm `tnv`, DB `keycloak_dev2`@192.168.60.25:9999. **tnv-service DEV** vẫn host này; staging thì IAM tne5.
- **Đừng nhầm `iam-dev` (tnv) với deployment `iam-dev` của tne5 (host `iam.dev-v3`)** — luôn phân biệt theo HOST.

## Gotcha 1b — Vector `sync` ≠ CDC; Yugabyte ≠ DB Keycloak
- App ArgoCD **`sync`** = Vector, Kafka `user_info` → Elasticsearch (search). **Không** đồng bộ identity.
- App **`cdc`** = Mongo change stream → IAM `updateUser`. Webhook IAM→profile V5 chạy trên **api** (`POST /external/users/sync`), không trên `cdc`/`sync`.
- **Hai DB tên na ná:** `keycloak_dev` @ `.80.35` = IAM; Yugabyte `trangnguyen_dev` bảng `user` @ `.80.39` = **profile V5**. Không tra user V5 trong PG Keycloak và ngược lại.
- Federation JAR `keycloak-rest-provider-6.0.4` vẫn trong image IAM (`dev-2026-08-28_...`). Form login STAG = IAM tne5; federation vẫn có thể chạy khi **local miss**. `cdc_logs SUCCESS` ≠ user đã có trên V5.
- Victoria Logs có thể **trống** với tne5-dev iam/api — không dùng log rỗng làm bằng chứng zero federation (R1 chưa đo, 2026-09-07).

## Gotcha 2 — app→app đi qua HAProxy public
- Ở tnv/bcn, service **KHÔNG gọi Service k8s nội bộ**: đi vòng qua domain public → HAProxy `192.168.60.6` → quay lại cụm (`hostAliases` pin IP LB).
- Ngoại lệ: `media-server` dùng Service `redis` nội bộ.
- **Hệ quả:** domain không có trong HAProxy map bị **silent-drop** ("treo không response"). Trace timeout app→app → check HAProxy map trước.
- **VNMF:** zone `vnmf.edu.vn`, cert **`cert_vnmf`** (không dùng wildcard `trangnguyen.edu.vn`). DEV `dev.vnmf.edu.vn` + PROD `vnmf.edu.vn` — **2 HTTPRoute cùng hostname**: `/` → `vnmf-frontend`; `/admin /api /uploads…` → `vnmf-cms-landing`. PathPrefix `/` của FE khớp mọi URL — Gateway phải ưu tiên path CMS. Chi tiết [`vnmf.yaml`](../catalog/products/vnmf.yaml).

## Gotcha 3 — ENV không suy từ tên; tag thật ở `.argocd-source-*`
- Tag đang chạy = `.../.argocd-source-<app>-<env>.yaml`, **KHÔNG** phải tag pin trong `values.yaml`.
- Cùng nhánh dev có image tag lệch tên ENV: `hoc-thi-2` tag `staging` (host `thi-stag-v3`); `keycloak-cluster` tag `prod`.
- => KHÔNG suy ENV từ namespace/branch; đọc image tag thực trước khi kết luận.

## Gotcha 4 — PROD: repo config mới + repo manifest CŨ song song
- Verify 2026-11-13: app PROD trên Platform (`tnv-prod`, `tne5-prod`, `bcn-prod`) chạy từ `devops/tnv/<tnv|tne5|bcn>-argocd-config` nhánh **`prod`**.
- App PROD **chưa** lên Platform có thể vẫn ở repo cũ: v2 `tnv/devops/tnv-argocd-manifest` nhánh `tnv/prod`; bcn `devops/bcn-argocd-manifest` nhánh `bcn/prod`. Xem `source.repoUrl` của `argocd_get_app` trước khi kết luận.
- `tnv/dev`,`tnv/staging` của manifest cũ = **đã chết** (chỉ tra env cũ; ConfigMap có secret plaintext — chỉ đọc).

## Gotcha 5 — Noibo = support_tnv2, chạy chung env tnv
- `support-tnv2-cms` (host `noibo-stage`), `support-tnv2-api` (host `noibo-api`), source group `bancn`, deploy trong namespace/infra V2.
