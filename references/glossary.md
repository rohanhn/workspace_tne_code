# Glossary

- **STAG**: staging / QA. Platform MCP field `environments` may say `uat`.
- **GitOps repo**: `*-argocd-config` — manifests, not application source.
- **orchestration**: this repo (`workspace_tne_code`).
- **profile V5**: hàng trong Yugabyte `trangnguyen_dev.user` (`user.id` UUID, `keycloak_user_id`, `idv0`). Không phải bản ghi Keycloak trong PG `keycloak_dev`.
- **federation (IAM)**: `LegacyProvider` trên IAM tne5 — local miss → `GET /user-migration/:username` (Yugabyte) rồi `POST` verify password KC cũ (`KEYCLOAK_BASE_URL`). Form STAG vẫn `iam.dev-v3`; federation là bước trong IAM, không phải user tự mở host `iam-dev`.
- **R1**: tỉ lệ username login IAM **không** có local `tnv-main` (federation miss). Chưa đo được 2026-09-07 — Victoria Logs tne5-dev iam/api trống.
- **R2**: tỉ lệ gọi `GET`/`POST /user-migration` trên api.
- **Vector `sync`**: app `tne5-dev-sync` (timberio/vector) — Kafka `user_info` → ES. Không phải CDC, không phải webhook IAM.
- **CDC (V5)**: app `tne5-dev-cdc` — Mongo `users` (bỏ `source: 'new'`) → Admin API IAM. `cdc_logs SUCCESS` ≠ user đã có trên V5.
- **webhook IAM→V5**: phasetwo `POST /external/users/sync` trên **api** (BullMQ) — IAM tạo/sửa → profile V5 → Mongo `source: new`.
- **VNMF**: website in-house BCN `vnmf.edu.vn` (DEV `dev.vnmf.edu.vn`) — Next.js + Strapi, 2 HTTPRoute cùng host. Catalog [`vnmf.yaml`](../catalog/products/vnmf.yaml). Không phải HUB V5.
