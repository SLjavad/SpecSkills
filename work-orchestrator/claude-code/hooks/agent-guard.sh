#!/usr/bin/env bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
input="$(tr -d '\r\n')"

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
  exit 0
}

field() {
  printf '%s' "$2" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p"
}

case "$input" in
  *'"tool_name"'*) ;;
  *) deny "agent-guard could not read the hook input, so the subagent launch was blocked." ;;
esac

tool="$(field tool_name "$input")"
[ "$tool" = "Agent" ] || [ "$tool" = "Task" ] || exit 0

tool_input="${input#*\"tool_input\"}"
name="$(field subagent_type "$tool_input")"
name="${name:-general-purpose}"
model="$(field model "$tool_input")"

if printf '%s' "$model" | grep -qiE 'opus|fable|mythos'; then
  deny "Subagents never run on the top tier; '$model' was requested for '$name'. Run it on Sonnet or Haiku, or do the work in this session."
fi

if [ ! -f "$dir/agent-guard.allow" ] || ! tr -d '\r' < "$dir/agent-guard.allow" | grep -qxF "$name"; then
  allowed="$( [ -f "$dir/agent-guard.allow" ] && tr -d '\r' < "$dir/agent-guard.allow" | paste -sd ',' - | sed 's/,/, /g')"
  deny "'$name' is not an allowed subagent. Allowed: ${allowed:-none}. For code search use 'scout'."
fi

exit 0
