# Systems overview (digest)

Nguồn chi tiết & luôn cập nhật: repo `devops/tnv/tnv-troubleshoot-helper` (branch `main`) —
`systems/<hệ>/{OVERVIEW,domains,loadbalancers,services,infra}.md`, `runbooks/`, `howto/`, `notes/`, `sessions/`, `reports/`.
`credentials/` bị gitignore — **không đọc secret**.

> Nguyên tắc: orchestration KHÔNG chép lại repo trên (nhanh lỗi thời). File này chỉ giữ "hằng số" ít đổi + trỏ tới OVERVIEW gốc. Khi trace/QA, đọc `systems/<hệ>/OVERVIEW.md` gốc trước.

## Bản đồ quan hệ liên sản phẩm

- **v5 (tne5) = HUB** trang chủ `trangnguyen.edu.vn` → điều hướng user sang **v6 (tnmath)** và **v2 (tnv)** qua domain. Lỗi báo ở trang chủ có thể nằm ở tne5 hoặc hệ đích.
- **IAM trung tâm = tne5** (`v5-identity`, host `iam.dev-v3`, realm `tnv-main`/`tne-main`): v6 + phần lớn v2/v5 auth vào đây → **SPOF auth**. Đang migrate user tnv sang đây (lazy migration `keycloak-rest-provider`; listener `AdminUserCreationInterceptor` gọi webhook khi tạo user).
- **KC v2 (cũ)** = `tnv/keycloak` (host `iam-dev`, realm `tnv`): cho một số app cms/quantri. Phân biệt với IAM tne5 **theo HOST**.
- **Đồng bộ user** V2 ↔ V5 ↔ KC qua 2 service **`cdc`** và **`sync`** nằm trong V5. Lỗi login/user lệch → kiểm 2 service này trước.
- **V2 session trong Redis** (không phải KC token thuần). Lỗi session V2 → soi Redis.
- **V5 = master data** (trường/huyện/tỉnh) cấp REST cho V khác. Sửa schema master data ở V5 → cân nhắc consumer V2/V6.
- Tất cả deploy trên **Kubernetes** (ArgoCD GitOps + Platform MCP).

## Digest hạ tầng theo hệ

### v2 (tnv) — micro-service · `systems/tnv/OVERVIEW.md`
- Cụm `cluster-dev-tnv` (RKE2, master .60.141, worker .144-146), ns `tnv-dev`/`tnv-staging`, Gateway API (traefik :8012) sau HAProxy `192.168.60.6`.
- Datastore IP tĩnh dùng chung: Mongo .60.21-24 (**DB chính**), Redis .60.21-23 (**session**), **Kafka .60.31/32/44** (thi online ~500k CCU), **RabbitMQ .60.26** (task background), PG .60.25:9999, ES 10.0.0.207, ClickHouse 10.0.0.58, MinIO (object storage). Secret qua Vault ExternalSecret.
- Sentry self-host: `tnv-service`=proj4, `tnv2-learn-exam`=3, `tnv2-learn-exam-v2`=13.
- Nghẽn thi online thường ở **Kafka/consumer** (throughput), không phải API stateless.

### v5 (tne5) — monolith · `systems/tne5/OVERVIEW.md`
- ns `tn-dev`, nginx ingress. BE `api` (Node.js :8000 monolith) + `cdc` (chung image `tne5/backend/v5`).
- DB: **YugabyteDB .80.39:5433** (chính), Redis Sentinel .80.39-40, Kafka .80.48-50, ES .80.45-47, ClickHouse .80.56, Mongo .60.21-24 (chung).
- Pipeline Vector: `pipe` (Kafka → ClickHouse, learning log), `sync` (Kafka topic `user_info` → ES). Cụm cũ `.80.35` (Directus/Gotenberg/PG-KC).

### v6 (tnmath) — micro-service · `systems/tnmath/OVERVIEW.md` + `notes/tnmath.md`
- NestJS + Python, realtime MQTT/EMQX, gateway APISIX (api/admin/website). Cụm pre-UAT `.140.x`, prod `10.80.0.x`.
- PG .140.34:5433, Mongo .140.61-63, Redis .140.41-43, Kafka .140.81-83, ES .140.52, MinIO .140.51:9002, EMQX .140.71-73.
- Source gốc tinhvan → mirror group `tnmath`. **Realtime & loadtest là điểm nóng** (xem `runbooks/tnmath-preuat-loadtest-timeout.md`).

### bcn (in-house) · `systems/bcn/OVERVIEW.md`
- Dev ns `bcn-dev` chung cụm `cluster-dev-tnv`. crm (Laravel, MySQL+Redis .60.33), crm2 (`erp/crm-v2`, FastAPI+SPA), chatbot (`tne-chat`, backend n8n), vnmf. Vault KV `bcn`.
- **Noibo = `support_tnv2`**: deploy trong env **tnv** (`support-tnv2-cms` host `noibo-stage`, `support-tnv2-api` host `noibo-api`), source group `bancn`.

### lachcach · `systems/lachcach/OVERVIEW.md`
- OVERVIEW còn TODO (chưa tài liệu hóa đầy đủ). Deploy `lachcach-staging` chung cụm tnv; GitOps `devops/tnv/lachcach-argocd-config`.

## PROD GitOps (đọc kỹ trước khi trace PROD)
- **v2 PROD** chạy repo CŨ `tnv/devops/tnv-argocd-manifest` nhánh **`tnv/prod`** (44 app). Tag thật = `tnv-services/<app>/.argocd-source-<app>-prod.yaml`. `devops/argocd/tnv-argocd-config-prod` (108) mới `Initial commit` → **chưa dùng**.
- **bcn PROD** chạy repo cũ `devops/bcn-argocd-manifest` nhánh `bcn/prod` (mỗi app 1 ns `bcn-<app>-prod`, cluster `10.0.0.20:6443`).
- **Tag đang chạy thật = file `.argocd-source-*.yaml`**, KHÔNG phải tag pin trong `values.yaml` (mọi hệ).
