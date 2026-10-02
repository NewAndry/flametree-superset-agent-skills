# Flametree Analytics MCP plugin installer for Claude Code (Windows).
#
#   powershell -ExecutionPolicy Bypass -c "irm https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills/-/raw/main/install.ps1 | iex"
#
# Stand: dev by default; pick another with FLAMETREE_STAND (prod, demo, test, dev):
#   powershell -ExecutionPolicy Bypass -c "$env:FLAMETREE_STAND='test'; irm https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills/-/raw/main/install.ps1 | iex"
# or, when run as a file: .\install.ps1 test
#
# 1. registers the marketplace and installs the stand's plugin (MCP server + skills);
# 2. opens a terminal window that runs `claude mcp login …` — the browser shows the
#    Flametree portal sign-in; with an active portal session it completes without clicks;
# 3. waits until the server reports Connected.
# Safe to re-run. Needs the `claude` CLI on PATH.

$ErrorActionPreference = "Stop"
$Repo = "https://gitlab.enfint.ai/flametree/flametree-superset-agent-skills.git"
$Marketplace = "flametree"

$Stand = if ($args.Count -gt 0) { "$($args[0])" } elseif ($env:FLAMETREE_STAND) { $env:FLAMETREE_STAND } else { "dev" }
$Stand = $Stand.ToLower()
$Stands = @{
    "prod" = @{ Plugin = "flametree-analytics";      Server = "flametree" }
    "demo" = @{ Plugin = "flametree-analytics-demo"; Server = "flametree-demo" }
    "test" = @{ Plugin = "flametree-analytics-test"; Server = "flametree-test" }
    "dev"  = @{ Plugin = "flametree-analytics-dev";  Server = "flametree-dev" }
}
if (-not $Stands.ContainsKey($Stand)) { throw "Unknown stand '$Stand'. Use one of: prod, demo, test, dev." }
$PluginName = $Stands[$Stand].Plugin
$Plugin = "$PluginName@$Marketplace"
$Server = "plugin:${PluginName}:$($Stands[$Stand].Server)"

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    throw "The 'claude' CLI is not on PATH. Install Claude Code first: https://code.claude.com/docs/en/desktop"
}

Step "Stand: $Stand"
Step "Marketplace '$Marketplace'"
$list = (& claude plugin marketplace list 2>&1 | Out-String)
if ($list -match [regex]::Escape($Marketplace)) {
    & claude plugin marketplace update $Marketplace | Out-Null
} else {
    & claude plugin marketplace add $Repo | Out-Null
}

Step "Plugin $Plugin"
& claude plugin install $Plugin | Out-Null

$servers = (& claude mcp list 2>&1 | Out-String)
if ($servers -match "$([regex]::Escape($Server)).*Connected") {
    Step "Already signed in"
} else {
    Step "Sign-in: a terminal window and a browser tab with the Flametree portal login open now"
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "claude mcp login $Server || pause"
    $deadline = (Get-Date).AddMinutes(3)
    $connected = $false
    while ((Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 5
        $servers = (& claude mcp list 2>&1 | Out-String)
        if ($servers -match "$([regex]::Escape($Server)).*Connected") { $connected = $true; break }
    }
    if (-not $connected) {
        Write-Warning "Sign-in not completed within 3 minutes. Finish it in the opened window, or run: claude mcp login $Server"
    } else {
        Step "Signed in"
    }
}

Write-Host ""
Write-Host "Done. Start a new Claude Code session (or run /reload-plugins) and ask Claude to list your Flametree tenants." -ForegroundColor Green
