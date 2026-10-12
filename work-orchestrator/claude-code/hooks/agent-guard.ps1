$ErrorActionPreference = 'Stop'

function Deny([string] $Reason) {
    $decision = @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = $Reason
        }
    }
    [Console]::Out.Write(($decision | ConvertTo-Json -Compress -Depth 5))
    exit 0
}

try {
    $hookEvent = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    Deny 'agent-guard could not read the hook input, so the subagent launch was blocked.'
}

if (@('Agent', 'Task') -notcontains $hookEvent.tool_name) {
    exit 0
}

$toolInput = $hookEvent.tool_input
$name = if ($toolInput.subagent_type) { [string] $toolInput.subagent_type } else { 'general-purpose' }
$model = $toolInput.model

if ($model -is [string] -and $model -match 'opus|fable|mythos') {
    Deny "Subagents never run on the top tier; '$model' was requested for '$name'. Run it on Sonnet or Haiku, or do the work in this session."
}

$allowFile = Join-Path $PSScriptRoot 'agent-guard.allow'
$allowed = @()
if (Test-Path -LiteralPath $allowFile) {
    $allowed = @(Get-Content -LiteralPath $allowFile | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

if ($allowed -cnotcontains $name) {
    $list = if ($allowed.Count) { $allowed -join ', ' } else { 'none' }
    Deny "'$name' is not an allowed subagent. Allowed: $list. For code search use 'scout'."
}

exit 0
