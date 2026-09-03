---
name: qa-env-compare
description: Compares DEV vs STAG (and PROD when cataloged) ArgoCD apps — image tags, Helm values, sync/health. Use when the user asks QA, môi trường, lệch env, staging vs dev, or compare deployments.
---

# QA / compare environments

## Workflow

1. Read `catalog/environments.yaml` and the product catalog file.
2. Emit `ENV:` for each side of the comparison (usually DEV vs STAG).
3. `platform_get_project_overview` for both platform projects.
4. Pair apps by suffix (`tnv-dev-X` vs `tnv-staging-X`). Call `argocd_get_app` per pair as needed.
5. Diff: image repository/tag, `valueFiles`, `targetRevision`, health/sync.
6. List apps present on only one env.

## Forbidden

Do not edit GitOps, sync, or restart to "make them match".

## Output

- Table: app | DEV tag | STAG tag | health | notes
- Apps missing on one side
- Tag/namespace mismatches (e.g. staging image on dev namespace)
