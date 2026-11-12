---
name: dev-feature
description: Implements a new feature on local product clones (catalog shared.clone_root) using product catalog (especially shared V2/V5 frontend). Use when the user asks to build a feature, implement, code a ticket, or develop on a TNE product.
---

# Dev feature

## Workflow

1. Read product catalog. Identify source repo vs GitOps repo (do not implement in argocd-config unless asked).
2. If change touches FE: confirm `exam-page` (V2 hoc-thi) vs `v5` (V5 web) vs both.
3. Work on the workspace folder that is the git clone. Do not nest clones inside orchestration.
4. Branch from the product's default (ask if unknown; BCN seen `develop` / `master`).
5. Implement + local DEV test. Do not push or open MR unless the user asks.
6. Call out cross-product risk (shared FE, shared APIs).

## Output

Diff summary, files touched, how to test on DEV, residual risks.
