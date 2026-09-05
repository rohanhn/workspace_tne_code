---
name: monitor-team
description: Snapshot of team delivery — open MRs, failed pipelines, ArgoCD health, Planka board. Use when the user asks monitor team, standup digest, MR kẹt, pipeline đỏ, or board status.
---

# Monitor team

## Workflow

1. Scope: one product or all `verified: true` catalog entries.
2. Platform overview / ArgoCD health / metrics: call GET immediately, do not ask.
3. GitLab MCP (if authenticated): open MRs, failed pipelines on known project ids.
4. Planka: `planka_list_projects` — read board **Trạng Nguyên V2**. Do not create/move cards without confirm.

## Output

Digest: blocked MRs, red pipelines, degraded apps, notable board cards. No unsolicited comments on GitLab.
