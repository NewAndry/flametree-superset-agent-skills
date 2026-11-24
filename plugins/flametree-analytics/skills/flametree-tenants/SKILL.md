---
name: flametree-tenants
description: Tenants (companies) in Flametree analytics through the Flametree MCP server. Use when the user mentions a company, a client or a tenant, asks whose data this is, asks to switch, or when list_my_tenants returned more than one tenant.
---

# Tenants in the Flametree MCP

All data, charts, dashboards and portal publishing belong to the **active tenant**. Rows of other tenants are filtered out on the server; they cannot be requested, so do not try.

## Rules

1. Call `list_my_tenants` once at the start of the session. It returns `active_tenant`, `home_tenant` and a list marked `home` (home tenant), `extra` (additional access), `any` (platform staff, all tenants available).
2. With a single tenant, do not ask and do not mention it.
3. With more than one tenant, if the user did not say which company to work with, ask before the first data request: "Which company are we working with: A or B?". Do not show a list longer than ten in full; ask the user to name the company.
4. Switching: `use_tenant(<id or exact name>)`. The choice is stored on the server and applies to later sessions too; do not repeat it.
5. If the user names a company that is not in the list, say there is no access and show the available ones. Do not pick a similar name.
6. After a switch, dashboards built earlier show the new tenant's data automatically; no need to rebuild them.

## What to tell the user

- Call the active tenant by its name; do not show the id unless asked.
- When the user asks why something is empty, first check the active tenant with `list_my_tenants`: platform staff have the system tenant as home, which has almost no data; switch to the company's tenant.
- "MCP access denied" means the user's email is not linked to a tenant in the portal. Explain it and stop.
