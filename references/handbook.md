# Handbook làm việc — Agent TNE

Sổ tay quy trình cho 4 nhóm task: **Review code / MR**, **Debug lỗi**, **Dev feature**, **Security scan**.
Áp dụng cho agent chạy trên Cursor + GitLab MCP workspace của hệ thống TNE.

## Nguyên tắc chung (đọc trước MỌI task)

- **ENV guard** (rule `00-environment-guard.mdc`): dòng đầu mọi câu trả lời ops/dev/review/hotfix = `ENV: DEV | STAG | PROD | UNKNOWN` + namespace/platform project/ArgoCD app nếu biết. Thiếu ENV → vẫn GET overview, hỏi ENV, **không** kết luận, KHÔNG mặc định PROD. **Đề xuất sửa code chỉ khi user yêu cầu.** PROD = **chỉ đọc**; **restart PROD cấm tuyệt đối**.
- **MCP routing** (rule `02-mcp-routing.mdc`): runtime (pod/log/metric/sync) = `platform-system`; GitLab (MR/diff/file/pipeline) = server workspace `project-0-workspace_tne_code-gitlab-tne-ws`. KHÔNG dùng `user-gitlab-tne`.
- **Catalog trước** (rule `03-multi-product.mdc`): đọc `catalog/products.yaml` → `catalog/products/<slug>.yaml`; tra ops chi tiết ở `references/systems-overview.md` + `references/naming-and-gotchas.md` + repo `devops/tnv/tnv-troubleshoot-helper`.
- **Confirm before write** (rule `01-confirm-before-write.mdc`): GET/READ MCP (overview, diff, metrics, list/get) **gọi ngay, không hỏi** — **trừ** `argocd_query_app_logs`. Comment MR / approve / merge / tạo MR/branch / push / restart DEV-STAG / `request_log_access` / Planka write → chỉ làm khi user xác nhận **tường minh**. Restart PROD: cấm tuyệt đối.
- **Gotcha thường trúng:** tag chạy thật ở `.argocd-source-*.yaml` (không phải `values.yaml`); ENV không suy từ namespace/branch; PROD trên Platform chạy `*-argocd-config` nhánh `prod`, app chưa lên Platform có thể còn ở repo manifest CŨ; app→app đi qua HAProxy `192.168.60.6` (domain thiếu map = silent-drop); IAM có 2 Keycloak phân biệt theo HOST; app ArgoCD ≠ tên repo (bảng mapping trong `naming-and-gotchas.md`).

---

## 1. Review code / Review MR

> Skill: `code-review-mr`. Tùy chọn tăng cường: subagent **Bugbot** (skill `review-bugbot`).

**Mục đích:** đánh giá chất lượng + rủi ro của thay đổi trước khi merge; KHÔNG tự comment/approve/merge.

**Input cần có:** URL MR hoặc `project_path` + IID. Thiếu → hỏi. Xác định ENV mà MR nhắm tới (branch đích).

**Quy trình:**
1. Lấy metadata + diff qua GitLab MCP ws: `get_merge_request`, `get_merge_request_diffs`/`list_merge_request_diffs`, `get_merge_request_notes`, `list_merge_request_pipelines`, `get_merge_request_approval_state`.
2. Map repo → sản phẩm qua catalog (chú ý tên lệch app↔repo). Nếu repo đã là clone trong workspace → đọc file local để có ngữ cảnh đầy đủ.
3. Chấm theo **checklist** (dưới). Ghi kèm `file:line` cho từng phát hiện.
4. Kiểm pipeline MR: nếu đỏ, nêu job/lý do (đọc log qua `gitlab_query_pipeline_log` — không cần grant).
5. Soạn nhận xét **dưới dạng draft**; chỉ post/approve/merge khi user confirm đúng IID + hành động.

**Checklist:**
- **Correctness:** logic, edge case, lỗi null/timezone/tiền tệ, N+1 query, rò rỉ tài nguyên.
- **Security:** input validation, authz (đúng realm KC nào?), secret hardcode, SQL/NoSQL injection, SSRF (nhớ app→app qua HAProxy public), CORS. (Sâu hơn → mục 4.)
- **Tests:** có test cho nhánh logic mới? migration có rollback?
- **Cross-product (đặc thù TNE):**
  - Sửa FE `exam-page` (V2) hay `v5` (V5) → ảnh hưởng parity layout + link điều hướng chéo domain bên kia.
  - Sửa schema **master data V5** (trường/huyện/tỉnh) → ảnh hưởng consumer V2/V6 qua REST.
  - Đụng webhook **api** (`/external/users/sync`, `/user-migration`) / **cdc** / realm KC → ảnh hưởng đăng nhập/profile. App Vector **`sync`** chỉ ES search — không gộp với CDC.
  - Monorepo `tnv2-learn-exam-v2`: 1 thay đổi build nhiều image → nêu image nào bị ảnh hưởng.
- **Ops/config:** đổi image tag phải sửa `.argocd-source-*` đúng ENV; đừng tưởng `values.yaml` là tag chạy.

**Output:** phân nhóm **Critical (phải sửa) / Suggestion / Nice-to-have** + đoạn draft comment (chưa post). Dòng đầu `ENV:`.

**Cấm tự động:** `create_note`, `approve_merge_request`, `merge_merge_request` khi chưa confirm từng IID.

---

## 2. Debug lỗi

> Skill: `trace-prod-incident`. Dùng cho bug PROD/STAG, CS ticket, hotfix, outage.

**Mục đích:** khoanh vùng sản phẩm → app ArgoCD → bằng chứng (log/metric/tag/commit). KHÔNG apply lên PROD. Đề xuất sửa code/hotfix **chỉ khi user yêu cầu**.

**Input cần có:** triệu chứng, sản phẩm (nếu biết), thời điểm, ENV. Thiếu ENV → vẫn GET overview, hỏi ENV, không kết luận/hotfix.

**Quy trình:**
1. **Đọc `tnv-troubleshoot-helper` TRƯỚC:** `systems/<hệ>/OVERVIEW.md` theo đường traffic domain → LB → service → infra, `notes/<hệ>.md`, `runbooks/`. Đây là bản đồ vận hành sống.
2. Map triệu chứng → sản phẩm/app qua catalog + `references/`. Chú ý domain public → HAProxy: timeout "treo không response" thường do domain thiếu trong HAProxy map (silent-drop).
3. `platform_get_project_overview(projectId)` → tình trạng sync/health các app của ENV đó.
4. `argocd_get_app(appName)` → pod, **image tag thật** (`.argocd-source-*`), Helm values, GitOps path.
5. **Log:** không gọi ngay `argocd_query_app_logs`. Confirm app + đọc log → `request_log_access` (1 lần/app) → đưa URL → sau grant mới `argocd_query_app_logs`. Overview/metrics/pipeline log GitLab gọi thẳng.
6. Sentry (nếu BE có project): đối chiếu lỗi theo thời điểm.
7. Đối chiếu image tag ↔ commit GitLab (MR gần nhất). Nếu clone local có sẵn → đọc code.

**Heuristic khoanh nhanh (TNE):**
- Login/profile lệch toàn hệ → **IAM tne5** + webhook **api** (`POST /external/users/sync`) + **cdc** (Mongo→IAM). Thiếu user trên Elasticsearch → Vector **`sync`** (`user_info`→ES). Login riêng cms/quantri hoặc tnv-service **DEV** → **KC v2** (`tnv/keycloak`, host `iam-dev`). Federation local miss → `/user-migration` trên api. Victoria Logs có thể trống với tne5-dev iam/api — không kết luận từ log rỗng.
- Yugabyte `user` = profile V5, **không** phải DB Keycloak (`keycloak_dev` @ `.80.35`). `cdc_logs SUCCESS` ≠ user đã có trên V5.
- Session V2 hỏng → **Redis**. Thiếu dữ liệu trường/huyện/tỉnh → REST **V5 master data**.
- V2 thi online tải lớn (~500k CCU) nghẽn/mất bài → **Kafka** lag + `consumer`/`consumer-sync-data`. Task background trễ → **RabbitMQ**. Lỗi file/upload → **MinIO**. DB chính = **MongoDB**.
- V6 realtime/loadtest timeout → EMQX/MQTT + `runbooks/tnmath-preuat-loadtest-timeout.md`.
- Timeout app→app (tnv/bcn) → check HAProxy `192.168.60.6` map trước.

**Output:** theo `.cursor/skills/trace-prod-incident/output-template.md` — dòng đầu `ENV:`, tóm tắt triệu chứng → root-cause (hoặc giả thuyết + bằng chứng) → bước xác minh. Đề xuất hotfix **chỉ khi user yêu cầu** (mô tả, KHÔNG apply).

**Cấm tự động:** restart PROD (tuyệt đối). DEV/STAG: restart/sync/merge/push GitOps/đổi tag chỉ khi confirm. Không tự đề xuất sửa code. PROD tuyệt đối chỉ đọc.

---

## 3. Dev feature

> Skill: `dev-feature`. Làm trên clone dưới `shared.clone_root` (`C:\TungVu\OnlineStorage\OneDrive - Cong ty TNHH Dau tu Giao duc Trang Nguyen\source_code\<repo>`), KHÔNG nest trong orchestration.

**Mục đích:** implement feature/ticket trên DEV local, không tự push/mở MR.

**Input cần có:** mô tả feature, sản phẩm/repo (map catalog nếu thiếu), nhánh gốc.

**Quy trình:**
1. Đọc catalog → phân biệt **source repo** vs **GitOps repo** (KHÔNG code trong `*-argocd-config`/manifest trừ khi được yêu cầu).
2. Nếu đụng FE: confirm `exam-page` (V2) / `v5` (V5) / cả hai. Đụng layout/menu/link chéo → nhắc đồng bộ parity + điều hướng domain bên kia; nêu bên nào là nguồn thay đổi.
3. Làm việc trên đúng folder clone (git). Nhánh gốc theo default sản phẩm (hỏi nếu chưa rõ — BCN gặp cả `develop`/`main`/`master`; V6 `develop` trừ `frontend-arena`=`main`).
4. Implement. Với monorepo `tnv2-learn-exam-v2`: xác định workload/image bị ảnh hưởng (exam-api/learn-api/student-api/consumer/…).
5. Test local DEV. Nêu cách chạy/test.
6. **Không push, không mở MR** trừ khi user yêu cầu tường minh.

**Checklist trước khi coi là xong:**
- Tôn trọng tech stack repo (Node/Nest/Python/Laravel/FE framework tương ứng — xem catalog/systems-overview).
- Không hardcode secret; dùng cơ chế config/Vault của hệ.
- Đụng master data V5 / KC / webhook api / cdc → ghi rõ tác động chéo. Vector `sync` = ES only.
- Đổi API dùng chung → cân nhắc consumer (V2/V6 ↔ V5).
- Migration DB có script rollback.

**Output:** tóm tắt diff, danh sách file đụng, cách test trên DEV, rủi ro còn lại (đặc biệt cross-product). Dòng đầu `ENV: DEV`.

**Cấm tự động:** push, tạo branch remote, mở/merge MR, chạy trên STAG/PROD — trừ khi confirm.

---

## 4. Security scan

> Chưa có skill riêng. Tăng cường bằng subagent **Security Review** (skill `review-security`) cho diff cục bộ.

**Mục đích:** rà lỗ hổng trong thay đổi (MR/diff) hoặc một repo/service, ưu tiên theo bề mặt tấn công của TNE. Chỉ đọc + báo cáo; KHÔNG sửa/không commit.

**Input cần có:** phạm vi (MR/IID, branch diff, hoặc repo + đường dẫn), ENV liên quan. Với PROD chỉ đọc.

**Quy trình:**
1. Xác định phạm vi: diff (MR qua GitLab MCP ws) hay toàn repo (clone local). Nếu là diff cục bộ → chạy subagent **Security Review** (`review-security`) để soi sâu.
2. Liệt kê bề mặt tấn công theo kiến trúc (dùng `systems-overview.md`): endpoint public qua HAProxy, auth (realm KC nào), data store, message bus, object storage.
3. Rà theo **checklist** (dưới), ghi `file:line` + mức độ (Critical/High/Medium/Low) + cách khai thác + đề xuất khắc phục.
4. Kiểm secret: không có token/PAT/mật khẩu hardcode; secret phải qua **Vault ExternalSecret** (tnv) / Vault KV `bcn`. **Không in secret ra chat**; nếu phát hiện secret lộ trong code/log → báo vị trí, khuyến nghị revoke, KHÔNG dán giá trị.
5. Tổng hợp báo cáo xếp theo mức độ ưu tiên.

**Checklist bảo mật (TNE-specific):**
- **AuthN/AuthZ:** đúng Keycloak (IAM tne5 trung tâm vs KC v2 legacy — theo HOST)? Kiểm role/scope; tránh IDOR; V2 session Redis không đoán được/không cố định.
- **Injection:** SQL (Yugabyte/PG/MySQL), NoSQL (Mongo), command, template. Query có tham số hóa.
- **SSRF / app→app:** service gọi nhau qua domain public → HAProxy; kiểm URL do input điều khiển, whitelist host.
- **Secrets & config:** không hardcode; ExternalSecret/Vault; `.argocd-source-*`/manifest cũ (`tnv-argocd-manifest`, `bcn-argocd-manifest`) từng có ConfigMap secret plaintext → cảnh báo, chỉ đọc.
- **Upload/Storage:** MinIO — kiểm content-type, giới hạn kích thước, đường dẫn, quyền bucket/pre-signed URL.
- **Messaging:** Kafka/RabbitMQ/EMQX — topic/queue authz, không nhận payload không kiểm.
- **Transport & headers:** TLS, CORS, security headers; cookie `HttpOnly`/`Secure`/`SameSite`.
- **Dependencies:** lib lỗi thời/CVE (đặc biệt repo legacy như `api-payment`, FE cũ `hoc-thi`).
- **PII & logging:** không log PII/thông tin học sinh; tuân thủ khi trace.

**Output:** báo cáo xếp **Critical → Low**, mỗi mục: mô tả, vị trí, tác động, cách khắc phục. Dòng đầu `ENV:`. Nếu secret lộ: chỉ nêu vị trí + khuyến nghị revoke.

**Cấm tự động:** sửa code, commit, push, tạo issue/MR, dán nội dung secret — trừ khi confirm.

---

## Bảng tra nhanh

| Task | Skill | MCP chính | Ghi/Write? |
|---|---|---|---|
| Review code/MR | `code-review-mr` (+ Bugbot) | gitlab-tne-ws | GET ngay; ghi chỉ khi confirm IID + hành động |
| Debug lỗi | `trace-prod-incident` | platform-system (+ gitlab-tne-ws) | Không; đề xuất code chỉ khi user yêu cầu |
| Dev feature | `dev-feature` | gitlab-tne-ws (clone local) | Không push/MR trừ khi confirm |
| Security scan | `review-security` (subagent) | gitlab-tne-ws / clone local | Không (chỉ báo cáo) |

Mọi task: dòng đầu `ENV:` (thiếu ENV vẫn GET overview, không kết luận); đề xuất sửa code chỉ khi user yêu cầu; PROD chỉ đọc, **restart PROD cấm tuyệt đối**; không in PAT/secret; không commit `.cursor/mcp.json`.
