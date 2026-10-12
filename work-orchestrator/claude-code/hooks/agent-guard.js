const ALLOWED_SUBAGENTS = new Set([
  "runner",
  "scout",
  "log-digest",
  "doc-check",
  "general-purpose",
  "claude",
  "claude-code-guide",
  "statusline-setup",
]);

const SUBAGENT_TOOLS = new Set(["Agent", "Task"]);
const TOP_TIER_MODEL = /opus|fable|mythos/i;

function deny(reason) {
  process.stdout.write(
    JSON.stringify({
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: reason,
      },
    })
  );
}

function decide(event) {
  if (!SUBAGENT_TOOLS.has(event.tool_name)) {
    return;
  }

  const input = event.tool_input || {};
  const name = input.subagent_type || "general-purpose";

  if (typeof input.model === "string" && TOP_TIER_MODEL.test(input.model)) {
    deny(`Subagents never run on the top tier; "${input.model}" was requested for "${name}". Run it on Sonnet or Haiku, or do the work in this session.`);
    return;
  }

  if (!ALLOWED_SUBAGENTS.has(name)) {
    deny(`"${name}" is not an allowed subagent. Allowed: ${[...ALLOWED_SUBAGENTS].join(", ")}. For code search use "scout".`);
  }
}

let raw = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (raw += chunk));
process.stdin.on("end", () => {
  let event;
  try {
    event = JSON.parse(raw);
  } catch {
    deny("agent-guard could not read the hook input, so the subagent launch was blocked.");
    return;
  }
  decide(event);
});
