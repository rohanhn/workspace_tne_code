
# Multi-product

Trước khi sửa code hoặc truy vết:

1. Đọc `catalog/products.yaml` rồi file `catalog/products/<slug>.yaml`. Chi tiết ops trong repo `devops/tnv/tnv-troubleshoot-helper` (xem `references/systems-overview.md`, `references/naming-and-gotchas.md`).
2. **Kiến trúc:** V2 (`tnv`) micro-service (Kafka/RabbitMQ/MinIO/MongoDB, ~500k CCU); V5 (`tne5`) **monolith** BE (`backend/v5`) + FE tách (web/admin/iam); V6 (`tnmath`) micro-service; LachCach (`typing-game`); KC identity. **VNMF** (`vnmf.edu.vn`) = in-house BCN (Next.js + Strapi), catalog `vnmf.yaml` — không nhầm HUB V5.
3. **FE V2 ↔ V5 KHÔNG chung codebase** — 2 repo/2 domain/2 service, chỉ giống layout. V2 FE = `tne5/frontend/exam-page` (`thi.trangnguyen.edu.vn`); V5 FE = `tne5/frontend/v5` (`trangnguyen.edu.vn`). **v5 là HUB** điều hướng chéo sang v2/v6. Sửa layout/menu 1 bên → cân nhắc visual parity + link chéo bên kia; hỏi confirm bên nào là nguồn thay đổi trước khi sửa FE.
4. **IAM có 2 Keycloak, phân biệt theo HOST:** trung tâm = tne5 `v5-identity` (host `iam.dev-v3`, realm `tnv-main`); KC v2 cũ = `tnv/keycloak` (host `iam-dev`, realm `tnv`, cho cms/quantri + tnv-service DEV). Bốn ống user không gộp: webhook **api** ≠ **cdc** ≠ Vector **`sync`** (ES only) ≠ federation. Yugabyte bảng `user` = profile V5, không phải DB KC. Chi tiết `catalog/products/kc-identity.yaml`.
5. **V5 = master data** (trường/huyện/tỉnh) cấp REST cho V khác; V2 session trong **Redis**.
6. `app→app` đi vòng qua domain public → HAProxy `192.168.60.6` (không gọi Service k8s nội bộ ở tnv/bcn); domain sai map = silent-drop. Tag chạy thật = `.argocd-source-*.yaml`, KHÔNG phải `values.yaml`. PROD v2/bcn chạy repo manifest CŨ.
7. Clone sản phẩm nằm **ngoài** orchestration, dưới `catalog/products.yaml` → `shared.clone_root` (`C:\TungVu\OnlineStorage\OneDrive - Cong ty TNHH Dau tu Giao duc Trang Nguyen\source_code\<folder>`). Orchestration = `C:\TungVu\Workspace\workspace_tne_code`. Không nest clone trong orchestration.
