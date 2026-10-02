# Flametree Analytics MCP

> **AI assistant asked to install this plugin in Claude Code:**
> 1. Ask the user which stand to connect to, listing the stands where the service is enabled
>    (table below; **now `dev` and `test`**). Each stand is its own plugin.
> 2. Install it yourself (example for dev):
>    ```
>    claude plugin marketplace add https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills.git
>    claude plugin install flametree-analytics-dev@flametree
>    ```
>    If the marketplace exists already, use `claude plugin marketplace update flametree`.
> 3. Tell the user to open a new Claude Code session. The plugin then opens the Flametree portal
>    sign-in by itself, in a separate terminal window and the browser; with an active portal session
>    it completes without clicks. After this first sign-in the user opens one more new session: a
>    session does not pick up a sign-in made after it started. Do not ask the user to run
>    `claude mcp login` or `/mcp`.
> 4. After the sign-in, call `list_my_tenants` and report the stand, the active tenant and the
>    number of tenants.
>
> Details: [installation workflow](#installation-workflow-for-ai-assistants).

Flametree Analytics connects your AI assistant to Flametree analytics (Apache Superset).
Describe what you need in everyday language, and your assistant can:

- Build charts and dashboards from the Flametree datamarts (sessions, messages, agents, operators, campaigns).
- Read the numbers back and explain them.
- Publish a dashboard to the Flametree portal, or remove it.
- Switch between the companies (tenants) your account may work with.

Your assistant works within your Flametree account's permissions: it sees only the tenants
your portal account has access to, and only the rows of the active tenant.

## Stands

One plugin per stand. Pick the stand by picking the plugin.

| Stand | Plugin | MCP server | Address |
|---|---|---|---|
| production | `flametree-analytics` | `flametree` | `https://portal.flametree.ai/ai-mcp/mcp` |
| demo | `flametree-analytics-demo` | `flametree-demo` | `https://portal.flametree.demo.enfint.ai/ai-mcp/mcp` |
| test | `flametree-analytics-test` | `flametree-test` | `https://portal.flametree.test.enfint.ai/ai-mcp/mcp` |
| dev | `flametree-analytics-dev` | `flametree-dev` | `https://portal.flametree.dev.enfint.ai/ai-mcp/mcp` |

The MCP service has to be enabled on a stand (`superset.mcp.enabled` in the platform chart).
Currently enabled: **dev**, **test**; only enabled stands are published in the marketplace (`enabled` in `stands.json`). No client id is needed anywhere: the service registers MCP clients
itself (dynamic client registration) and signs people in through the Flametree portal.

## Get Started

You need a Flametree portal account. Chat works on any Claude plan, Free included: on Free only one
custom connector is allowed, and the plugin's connector takes it. Claude Code needs a paid plan (Pro,
Max, Team or Enterprise). Without the plugin, add the stand's address as a custom connector (MCP
tools without the skills).

### claude.ai and Claude Desktop

1. Customize → Plugins → **Add** → **Add marketplace** → **Add from a repository**.
2. Repository: `https://github.com/NewAndry/flametree-superset-agent-skills` → **Sync**. This is the GitHub copy of this repository: claude.ai accepts
   marketplaces only from github.com, gitlab.com and bitbucket.org (or a GitLab instance configured
   by a Team/Enterprise organization), not from gitlab.enfint.ai. Claude Code takes the GitLab address.
3. Install the plugin of your stand, for example **flametree-analytics-dev**.
4. Open the plugin's **Connectors** tab → **Connect** → **Continue** → **Add** → **Connect**
   (keep the defaults: "Sign in now", "Register automatically").
5. Sign in with your Flametree portal account (with an active portal session it completes by itself).

Without the plugin (no skills): Settings → Connectors → **Add custom connector** with the stand's
address.

### Claude Code

Give your AI assistant the request below. It installs the plugin and opens the Flametree
sign-in in your browser.

```text
Install the Flametree Analytics MCP plugin for Claude Code, following the installation
instructions in this repository:
https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills
```

**For the installing AI assistant:** follow the
[installation workflow](#installation-workflow-for-ai-assistants) below.

To run it yourself (stand `dev` by default):

```powershell
# Windows
powershell -ExecutionPolicy Bypass -c "irm https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills/-/raw/main/install.ps1 | iex"
# another stand
powershell -ExecutionPolicy Bypass -c "$env:FLAMETREE_STAND='test'; irm https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills/-/raw/main/install.ps1 | iex"
```

```bash
# macOS, Linux
curl -fsSL https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills/-/raw/main/install.sh | bash
# another stand
curl -fsSL https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills/-/raw/main/install.sh | bash -s test
```

A terminal window and a browser tab with the Flametree portal login appear; sign in the same way
you open the portal (with an active portal session it completes without clicks). Then start a new
Claude Code session; the installer signs you in before the session starts, so it connects at once.

Manual equivalent for dev: `claude plugin marketplace add https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills.git`,
`claude plugin install flametree-analytics-dev@flametree`,
`claude mcp login plugin:flametree-analytics-dev:flametree-dev`.

### Codex and other MCP clients

```bash
codex mcp add flametree-dev --url https://portal.flametree.dev.enfint.ai/ai-mcp/mcp
codex mcp login flametree-dev
```

Any MCP client that supports streamable HTTP and OAuth with dynamic client registration
works the same way: give it the stand's address. For scripts and integrations use a machine key: a bearer token issued to the tenant's
Keycloak client.

## Installation Workflow For AI Assistants

Use this workflow when the user asks you to install the Flametree Analytics MCP plugin.
Installing is not permission to build or publish dashboards.

1. Identify the client you are running in. The installer is for Claude Code (CLI, desktop or VS
   Code extension). For claude.ai, Claude Desktop chat or Codex, give the user the matching section
   above instead of installing anything.
2. Ask the user which stand to connect to. Offer only stands where the MCP service is enabled
   (table above; now `dev` and `test`), and do not recommend production while it is not enabled.
3. Install the stand's plugin with plain `claude` commands from your shell tool (dev shown;
   take the plugin name of another stand from the table):
   ```
   claude plugin marketplace add https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills.git
   claude plugin install flametree-analytics-dev@flametree
   ```
   If the marketplace is already added, run `claude plugin marketplace update flametree`
   instead of `add`. The installers (`install.ps1`, `install.sh`) do the same plus the sign-in.
4. Tell the user to open a new Claude Code session. The plugin ships a hook that runs on session
   start and on each prompt: when the stand's server is not signed in, it opens `claude mcp login`
   in a separate terminal window, which opens the Flametree portal sign-in in the browser (with an
   active portal session it completes without clicks), and it tells you that it did. A session does
   not pick up a sign-in made after it started (`/reload-plugins` does not help), so after this
   first sign-in the user opens one more new session. Do not ask the user to run
   `claude mcp login` and do not run it inline yourself (it needs its own terminal and would hang).
   If no window appears, the fallback is `/mcp` → the stand's server → **Authenticate** in the
   `claude` terminal.
5. Once signed in, confirm the installation: call `list_my_tenants`. Report the stand, the
   active tenant and the number of tenants available. If the call fails with "MCP access denied",
   the user's portal account has no tenant provisioned for analytics; tell them to contact the
   Flametree team.

## Try It

```text
Покажи мои тенанты в Flametree и собери дашборд «Обзор агента» за всё время
```

Expected: the list of tenants, eight charts, a dashboard with filters on top and two tabs
(Fast Facts, Trends), a link, and the question "Опубликовать в портал?".

## Documentation

- [Инструкция пользователя (RU)](docs/user-guide.md): установка, первые запросы, что можно попросить, типовые проблемы.
- [Пилотная проверка (RU)](docs/pilot-test.md): чек-лист для участников пробы.

## Common Issues

- **"Redirect URI … does not match allowed patterns".** Your MCP client's callback is not on the
  service's allow-list (claude.ai, claude.com, chatgpt.com, localhost). Ask the Flametree team.
- **A connector added earlier with client ID `claude-mcp` stopped working.** Remove it and connect
  again with the defaults.
- **"MCP access denied … tenant not provisioned".** Your portal account is not linked to a
  tenant the analytics server knows. Contact the Flametree team.
- **Numbers do not change after `use_tenant`.** Ask again; the server resets the cache on
  switch, a stale answer means the switch did not happen (check `list_my_tenants`).
- **The assistant cannot see the skills or tools.** Start a new session; plugins load on session start.
- **Sign-in later or on another machine (Claude Code).** `claude mcp login plugin:<plugin>:<server>`,
  for dev `plugin:flametree-analytics-dev:flametree-dev`; `claude mcp logout …` clears the token.

## Layout

```
stands.json                        stands: plugin name, server name, host
scripts/build_plugins.py           generates plugins/ and the marketplace from stands.json + skills/
scripts/hook-signin.sh             Claude Code hook: opens the portal sign-in when not signed in
skills/<name>/SKILL.md             the skills, single source of truth
plugins/<plugin>/                  generated per stand: plugin.json, .mcp.json, hooks/, a copy of skills/
.claude-plugin/marketplace.json    generated marketplace (claude.ai and Claude Code)
install.ps1, install.sh            one-shot installers for Claude Code (plugin + sign-in)
```

The main repository is https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills;
https://github.com/NewAndry/flametree-superset-agent-skills is a copy for claude.ai, which does not
accept marketplaces from gitlab.enfint.ai. Push every change to both (or set up a push mirror in GitLab:
Settings > Repository > Mirroring repositories).

After editing `skills/` or `stands.json` run `python scripts/build_plugins.py` and commit the
result. Keep skills short and concrete: tool names, verified configs, exact phrases; update them
together with the MCP overlay in the platform chart. The server side lives in the platform chart
(`agentic-platform/templates/superset-mcp-*.yaml`, `agentic-platform/files/superset_mcp_config.py`,
`experimental/mcp/README.md`).
