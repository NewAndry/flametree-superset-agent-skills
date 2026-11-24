---
name: flametree-analytics
description: Flametree analytics through the Flametree MCP server (Superset 6.1). Use when the user asks for a dashboard, a chart, numbers on sessions, messages, agents, operators or campaigns, an interpretation of the data, publishing a dashboard to the portal, or switching the tenant (company). Contains the datamart catalog and ready chart recipes; do not explore the datasets again.
---

# Flametree analytics through MCP

All data comes only from the Flametree MCP tools. No files; SQL Lab is closed for this role.
The catalog below replaces `get_dataset_info`: call it only for columns that are not listed here. If a call fails with "MCP access denied" or the portal returns 403, explain it and do not work around it. If a tool is not listed, find it with `search_tools` and run it with `call_tool`.

Building, styling and publishing dashboards: skill `flametree-dashboard-style`. Several companies: skill `flametree-tenants`.

## Datamart catalog

Every datamart is already filtered by tenant on the server; do not add a tenant_id filter.
Dataset ids (`dataset_id` for `generate_chart`) differ per stand: call `list_datasets` once per session and map the table names below to ids.

| Datamart | One row = | Default time column |
|---|---|---|
| `hp_sessions` | session (a customer dialog with a bot or an operator) | `session_start_time` |
| `hp_session_logs` | message in a dialog | `session_start_time` |
| `standard_calculated_hp_session_logs` | visible message, with who wrote before/after and the response time | `session_start_time` |
| `vw_human_agent_handled` | session handled by a human | `start_time_local` |
| `hp_communications` | communication of a legacy V1 campaign | `communications_start_date` |
| `vw_campaign_participants_v2` | V2 campaign participant | `contacts_created_on` |
| `vw_communications_v2` | V2 campaign communication | `communications_start_date` |

**hp_sessions**: the main datamart for sessions, load, agents, channels.
- `session_id`: count sessions with `COUNT_DISTINCT`. `session_ext_user_id`: unique customers, `COUNT_DISTINCT`.
- `session_logs_count`: messages per session (AVG = average dialog length).
- `session_session_type`: REGULAR = bot only, COPILOT / OPERATOR = with a human. Automation rate = share of REGULAR.
- `session_status`: status, e.g. resolved_by_operator. `session_reopened`: bool.
- `sessions_user_type`: channel, TELEGRAM / WHATSAPP / WEB and others.
- `agents_name`: AI agent; `session_operator_name`: operator; `agents_flow_type`: agent type.
- Time: `session_start_time`, `session_finish_time`, local `session_start_time_local`.
- Dataset metric: `count` (COUNT(*)).

**hp_session_logs**: messages, who writes how much.
- `session_logs_role`: HUMAN = customer, AI = bot, OPERATOR = operator. Count messages with `COUNT(*)`.
- `session_id`, `agents_name`, `sessions_user_type`, `session_session_type`: as in hp_sessions.

**standard_calculated_hp_session_logs**: response time, first response, who answered whom.
- `seconds_to_answer_to_previous_message`: seconds since the previous message. Average bot response time = AVG with filters `session_logs_role = AI` and `previous_message_role = HUMAN`; operator: the same with OPERATOR.
- `message_by_role_num`: number of the message of this role in the session (`= 1` is the first response).
- `previous_message_role`, `next_message_role`, `session_logs_role`, `agents_name`.

**vw_human_agent_handled**: operators, escalations.
- `operator_name`; `assignment_status` Assigned/Unassigned; `category` Resolved / Not Resolved / Unassigned / Other; `status`.

**vw_campaign_participants_v2**: campaign funnel, conversion.
- `campaigns_name`, `campaigns_status` ACTIVE/INACTIVE/ERROR; `participant_id` with COUNT_DISTINCT; `result_bool` true = success, false = failure, null = no result yet; `has_attempt`: whether there was a communication.

**vw_communications_v2**: delivery, touch statuses.
- `communications_status` Planned / Started / Delivered / Read / Replied / Completed / NoResponse / Canceled / Skipped / Failed; `communications_channel`; `campaigns_name`; `contacts_id`.

**hp_communications**: legacy V1 campaigns only; exclude `campaigns_is_inbound = true` (a technical agent wrapper).

## Chart recipes for generate_chart

Number: `{"chart_type":"big_number","metric":{"name":"<col>","aggregate":"<AGG>","label":"<label>"}}`
Line/bars: `{"chart_type":"xy","kind":"line"|"bar","x":{"name":"<col>","time_grain":"P1D"},"y":[{"name":"<col>","aggregate":"<AGG>","label":"<label>"}]}` (for categories, `x` without time_grain)
Table: `{"chart_type":"table","columns":[{"name":"<col>","aggregate":"<AGG>","label":"<label>"},…]}` (`groupby` may be ignored; for breakdowns use an `xy` bar)
AGG: SUM, AVG, COUNT, COUNT_DISTINCT, MAX, MIN, MEDIAN. Filters: `"filters":[{"column":"session_logs_role","op":"=","value":"AI"}]`; operators `=`, `!=`, `>`, `<`, `>=`, `<=`, `IN` (value is a list), `LIKE`. The exact schema of any chart type: `get_chart_type_schema(chart_type, include_examples=true)`.

| Request | Datamart | Config |
|---|---|---|
| Total sessions | `hp_sessions` | big_number, `session_id` COUNT_DISTINCT |
| Sessions by day | `hp_sessions` | xy line, x `session_start_time` P1D, y `session_id` COUNT_DISTINCT |
| Unique customers | `hp_sessions` | big_number, `session_ext_user_id` COUNT_DISTINCT |
| Average messages per session | `hp_sessions` | big_number, `session_logs_count` AVG |
| Sessions by agent | `hp_sessions` | xy bar, x `agents_name`, y `session_id` COUNT_DISTINCT |
| Sessions by channel | `hp_sessions` | xy bar, x `sessions_user_type`, y `session_id` COUNT_DISTINCT |
| Automation rate | `hp_sessions` | xy bar, x `session_session_type`, y `session_id` COUNT_DISTINCT (REGULAR = no human) |
| Messages by role | `hp_session_logs` | xy bar, x `session_logs_role`, y `session_id` COUNT |
| Average bot response time | `standard_calculated_hp_session_logs` | big_number, `seconds_to_answer_to_previous_message` AVG, filters `session_logs_role = AI` and `previous_message_role = HUMAN` |
| Average operator response time | `standard_calculated_hp_session_logs` | the same with OPERATOR |
| Escalations by operator | `vw_human_agent_handled` | xy bar, x `operator_name`, y `session_id` COUNT_DISTINCT |
| Campaign funnel | `vw_campaign_participants_v2` | xy bar, x `campaigns_name`, y `participant_id` COUNT_DISTINCT (filter `result_bool = true` for successes) |
| Communication statuses | `vw_communications_v2` | xy bar (or pie), x `communications_status`, y `contacts_id` COUNT |

Standard "agent overview" dashboard: total sessions, unique customers, average messages, average bot response time (big_number, Fast Facts tab), sessions by day, by channel, by agent, automation rate (xy, Trends tab). Eight charts, one generate_dashboard, one apply_dashboard_template.

## Stands

The stand is defined by the installed plugin: `flametree-analytics` (prod), `flametree-analytics-demo`, `-test`, `-dev`. The MCP server is named after the stand: `flametree`, `flametree-demo`, `flametree-test`, `flametree-dev`. If the user asks which stand they are connected to, name the server the answers come from. Data on dev and test is test data; `list_my_tenants` shows which tenants have it.
