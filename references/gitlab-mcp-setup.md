# GitLab MCP — dán PAT và test

Instance: `https://git.trangnguyen.edu.vn`  
Package: `@zereight/mcp-gitlab` (stdio). **Không** dùng `type: http` hay `url` trỏ REST `/api/v4`.

## 1. Dán PAT

Mở `.cursor/mcp.json` (bản local, gitignore). Thay đúng một chỗ:

```
GITLAB_PERSONAL_ACCESS_TOKEN: PASTE_GITLAB_PAT_HERE
```

Giữ nguyên:

- `GITLAB_API_URL` = `https://git.trangnguyen.edu.vn/api/v4`
- `GITLAB_READ_ONLY_MODE` = `true`

File mẫu (commit được): `.cursor/mcp.json.example`

## 2. Tránh server trùng

Nếu `C:\Users\<you>\.cursor\mcp.json` đã có `gitlab-tne` cũ (lẫn command + type http), **xóa hoặc tắt** block đó. Chỉ một server GitLab MCP.

`platform-system` giữ nguyên ở user mcp.json.

## 3. Quyền PAT (fine-grained, chỉ Read)

Tab User: User → Read  
Tab Group and project: Namespace/Group, Project, Merge request, Pipeline, Job, Code/Repository (+ Download nếu tách), Branch, Issue/Work item, Event — tất cả **Read**.  
Tab Global: không chọn.  
Không cấp Merge / Push / sudo / api.

## 4. Test (nhờ agent sau khi dán)

1. Settings → MCP → `gitlab-tne` xanh  
2. `health_check` → authenticated true  
3. `whoami`  
4. `list_namespaces`

403 `insufficient_granular_scope`: bổ sung đúng quyền ghi trong error, không nới write.
