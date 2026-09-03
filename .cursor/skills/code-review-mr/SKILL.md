---
name: code-review-mr
description: Reviews GitLab merge requests for TNE products using GitLab MCP diffs or Platform MR tools. Use when the user pastes an MR URL/IID, asks for code review, or review merge request.
---

# Code review MR

## Input

MR URL or `project_path` + IID. If missing, ask.

## Workflow

1. Prefer GitLab MCP when `health_check` is authenticated: `get_merge_request`, diffs, notes, pipelines, approval state.
2. Else Platform `gitlab_get_merge_request_detail` if available.
3. Checklist: correctness, security, tests, cross-product FE impact (V2/V5).
4. If the source repo is a workspace root, read local files for context.
5. **Do not** post comments, approve, or merge unless the user confirms the exact MR and action.

## Output

- Critical (must fix)
- Suggestion
- Nice-to-have
- Draft comment text (not posted)
