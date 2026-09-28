# API links giữa sản phẩm

Nguồn: đọc source `tne5/backend/v5` (id 115) 2026-09-07. Chi tiết ops: `systems/tne5/services/{api,cdc,sync,iam}.md`. Không bịa endpoint.

## Identity / user (V5 api ↔ IAM tne5 ↔ Mongo V2)

| Direction | Method + path | Ai gọi | Ghi chú |
|---|---|---|---|
| IAM → api | `POST /external/users/sync` | phasetwo events (ký `x-keycloak-signature`) | BullMQ `SYNC_KC_USER_QUEUE` → Yugabyte `user` → Kafka `user_info` → Mongo `source: 'new'` |
| IAM → api | `GET /user-migration/:username` | LegacyProvider (federation, local miss) | Đọc Yugabyte `user`, **không** Mongo |
| IAM → api | `POST /user-migration` | LegacyProvider | Verify password qua `KEYCLOAK_BASE_URL` (KC v2 cũ), rồi import `tnv-main` |
| IAM → api | `POST /user-migration/get-user-number` | `AdminUserCreationInterceptor` | Lỗi → user admin **không** được tạo trên KC |
| CDC → IAM | Admin API `updateUser` | `cdc` worker | Mongo change stream (bỏ `source: 'new'`). Không insert Yugabyte nếu KC OK |
| api → Kafka | topic `user_info` | `handleKcEvents` / CDC fallback | Consumer Vector `sync` → Elasticsearch (search only) |

IAM `hostAliases` live: `api.stag-v3.trangnguyen.edu.vn` → `192.168.60.6`.

V5 `POST /login` vẫn password-grant `KEYCLOAK_BASE_URL` (KC cũ) — đường riêng, không phải federation.

Master data REST (trường/huyện/tỉnh) V5 → V2/V6: chưa rà danh sách path ở đây — xem `catalog/products/v5-hoc.yaml` `master_data`.
