---
name: flametree-dashboard-style
description: How to build and style Flametree dashboards in Superset through the Flametree MCP server, and what to tell the user. Use when the user asks to build, rework, style or publish a dashboard, and after any generate_dashboard.
---

# Building and styling a Flametree dashboard

## Always the same order

1. Charts: `generate_chart` with `save_chart=true`, `chart_name` in the language of the request (recipes and the datamart catalog are in skill `flametree-analytics`).
2. Dashboard: `generate_dashboard(dashboard_title, chart_ids, published=true)`.
3. **Right away** `apply_dashboard_template(dashboard_id)`. It applies the house style of the standard agent dashboard: a filter bar on top (Period, Timegrain, Agent, Session Type, Channel, Campaign, only those that have columns), a Fast Facts tab with numbers four per row, a Trends tab with charts two per row, Arial, orange accents, number formats. Do not build the layout or CSS by hand; the tool does it deterministically.
4. Answer the user in three lines: the dashboard link (`url` from `apply_dashboard_template`, the same as `dashboard_url` from `generate_dashboard`), the charts in one line, and the question whether to publish it to the portal.
5. Publish only after an explicit yes: `publish_to_portal(dashboard_id, name)`, then give the portal page link. To remove it: `unpublish_from_portal`.

## Defaults

- Big numbers (`big_number`) for totals: total, average, share. Charts (`xy`): a line over dates, bars over categories. A table only when a list is requested.
- Standard "agent overview": total sessions, unique customers, average messages, average bot response time, sessions by day, by channel, by agent, automation rate. Eight charts.
- The default period in the filter is "No filter"; if the user named a period, pass it as `apply_dashboard_template(default_time_range=...)`, e.g. "Last month".
- Name the dashboard after the meaning of the request, without dates and without the word "dashboard".

## Changes

- "Change a chart": `update_chart` by id and nothing else; the style is already applied.
- "Add a chart": `generate_chart` + `add_chart_to_existing_dashboard`, then `apply_dashboard_template(dashboard_id)` again so the new chart joins the grid.
- Config validation error: fix it using the hint in the response; `get_chart_type_schema` gives the schema.

## Do not

- Show the user JSON configs or form_data; only the result and the link.
- Publish without confirmation, or publish someone else's dashboard.
- Pass `tenant_id` when publishing: the service takes the active tenant and finds its portal id itself. Do not publish under the system tenant (`00000000-…-0001`): the portal cannot open such a page.
