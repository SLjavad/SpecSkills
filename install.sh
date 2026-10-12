#!/usr/bin/env bash
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

case "$(uname -s)" in
  MINGW*|MSYS*|CYGWIN*)
    exec powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$(cygpath -w "$REPO/install.ps1")" "$@"
    ;;
esac

DRY_RUN=0
UNINSTALL=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      echo "Usage: ./install.sh [--dry-run] [--uninstall]"
      echo "  Installs every skill in this repository for Claude Code and any other agent tool found,"
      echo "  plus the Claude Code helpers, hooks and settings. --dry-run shows the plan and writes"
      echo "  nothing; --uninstall removes the helpers, hooks, their settings and the CLAUDE.md"
      echo "  exemption, and leaves the skills in place."
      exit 0
      ;;
    *) echo "Unknown option: $arg (see --help)"; exit 2 ;;
  esac
done

CONFIG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP="$CONFIG/backups/spec-skills/$(date +%Y%m%d-%H%M%S)"
CHANGED=0
MANUAL=0

report() {
  printf '  %-9s %s\n' "$1" "$2"
  case "$1" in added|updated|removed) CHANGED=1 ;; manual) MANUAL=1 ;; esac
}

backup() {
  local rel="${1#"$HOME"/}"
  rel="${rel#/}"
  mkdir -p "$BACKUP/$(dirname "$rel")"
  cp -p "$1" "$BACKUP/$rel"
}

put() {
  if [ -f "$2" ] && cmp -s "$1" "$2"; then
    report unchanged "$2"
    return
  fi
  if [ -f "$2" ]; then report updated "$2"; else report added "$2"; fi
  [ "$DRY_RUN" = 1 ] && return
  [ -f "$2" ] && backup "$2"
  mkdir -p "$(dirname "$2")"
  cp "$1" "$2"
}

remove() {
  [ -f "$1" ] || return
  report removed "$1"
  [ "$DRY_RUN" = 1 ] && return
  backup "$1"
  rm -f "$1"
}

same_dir() {
  [ -d "$1" ] && [ -d "$2" ] && [ "$(cd "$1" && pwd -P)" = "$(cd "$2" && pwd -P)" ]
}

sync_skill() {
  local src="$1" dest="$2" file rel
  while IFS= read -r file; do
    rel="${file#"$src"/}"
    put "$file" "$dest/$rel"
  done < <(find "$src" -type f | sort)
  [ -d "$dest" ] || return
  while IFS= read -r file; do
    rel="${file#"$dest"/}"
    [ -f "$src/$rel" ] || remove "$file"
  done < <(find "$dest" -type f | sort)
}

python_ok() {
  command -v python3 >/dev/null 2>&1 && python3 -c 'import json' >/dev/null 2>&1
}

SKILLS=()
if [ -d "$REPO/.git" ] && command -v git >/dev/null 2>&1; then
  while IFS= read -r path; do
    SKILLS+=("${path%/SKILL.md}")
  done < <(git -C "$REPO" ls-files | grep -E '^[^/]+/SKILL\.md$' | sort -u)
fi
if [ "${#SKILLS[@]}" -eq 0 ]; then
  for dir in "$REPO"/*/; do
    [ -f "$dir/SKILL.md" ] && SKILLS+=("$(basename "$dir")")
  done
fi

HELPERS=()
for skill in "${SKILLS[@]}"; do
  for file in "$REPO/$skill"/claude-code/agents/*.md; do
    [ -f "$file" ] && HELPERS+=("$file")
  done
done

HOOKS=""
for skill in "${SKILLS[@]}"; do
  list="$REPO/$skill/claude-code/hooks.list"
  [ -f "$list" ] || continue
  while read -r event matcher script timeout; do
    [ -n "${event:-}" ] || continue
    HOOKS+="$event	$matcher	$(dirname "$list")/hooks	$script	${timeout%$'\r'}"$'\n'
  done < <(tr -d '\r' < "$list")
done

if [ "$UNINSTALL" = 1 ]; then MODE=uninstall; else MODE=install; fi
if [ "$DRY_RUN" = 1 ]; then echo "spec-skills $MODE — dry run, nothing written ($CONFIG)"; else echo "spec-skills $MODE ($CONFIG)"; fi

SETTINGS="$CONFIG/settings.json"
if [ -f "$SETTINGS" ] && python_ok && ! python3 -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$SETTINGS" 2>/dev/null; then
  echo "$SETTINGS is not valid JSON; fix it, then run this again. Nothing was changed."
  exit 1
fi

if [ "$UNINSTALL" = 0 ]; then
  echo "Skills"
  TARGETS=("$CONFIG/skills")
  { [ -d "$HOME/.codex" ] || [ -d "$HOME/.cursor" ] || [ -d "$HOME/.gemini" ]; } && TARGETS+=("$HOME/.agents/skills")
  [ -d "$HOME/.copilot" ] && TARGETS+=("$HOME/.copilot/skills")
  for target in "${TARGETS[@]}"; do
    if same_dir "$REPO" "$target"; then
      report skipped "$target — this repository is that folder; a git pull keeps it current"
      continue
    fi
    for skill in "${SKILLS[@]}"; do
      sync_skill "$REPO/$skill" "$target/$skill"
    done
  done
fi

echo "Claude Code helpers"
HELPER_NAMES=()
for file in "${HELPERS[@]}"; do
  name="$(basename "$file" .md)"
  HELPER_NAMES+=("$name")
  if [ "$UNINSTALL" = 1 ]; then remove "$CONFIG/agents/$name.md"; else put "$file" "$CONFIG/agents/$name.md"; fi
done

echo "Claude Code hooks"
HOOK_SPEC=""
while IFS=$'\t' read -r event matcher dir script timeout; do
  [ -n "${event:-}" ] || continue
  target="$CONFIG/hooks/$script.sh"
  for other in "$CONFIG/hooks/$script".*; do
    case "$other" in "$target"|"$CONFIG/hooks/$script.allow") ;; *) remove "$other" ;; esac
  done
  if [ "$UNINSTALL" = 1 ]; then
    remove "$target"
    remove "$CONFIG/hooks/$script.allow"
  else
    put "$dir/$script.sh" "$target"
    if [ -f "$dir/$script.allow" ]; then
      allow="$(mktemp)"
      { tr -d '\r' < "$dir/$script.allow"; printf '%s\n' "${HELPER_NAMES[@]}"; } > "$allow"
      put "$allow" "$CONFIG/hooks/$script.allow"
      rm -f "$allow"
    fi
  fi
  HOOK_SPEC+="$event	$matcher	bash \"$target\"	$timeout	$script"$'\n'
done <<< "$HOOKS"

echo "Claude Code settings and instructions"
if python_ok; then
  RESULT="$(SS_SETTINGS="$SETTINGS" SS_CLAUDE_MD="$CONFIG/CLAUDE.md" SS_BACKUP="$BACKUP" SS_HOME="$HOME" \
    SS_MODE="$MODE" SS_DRY_RUN="$DRY_RUN" SS_HOOKS="$HOOK_SPEC" SS_HELPERS="${HELPER_NAMES[*]}" \
    python3 - <<'PYTHON'
import json, os, re, shutil, textwrap

settings_path = os.environ["SS_SETTINGS"]
claude_md = os.environ["SS_CLAUDE_MD"]
backup_root = os.environ["SS_BACKUP"]
home = os.environ["SS_HOME"]
uninstall = os.environ["SS_MODE"] == "uninstall"
dry_run = os.environ["SS_DRY_RUN"] == "1"
helpers = sorted(os.environ["SS_HELPERS"].split())
hooks = [line.split("\t") for line in os.environ["SS_HOOKS"].splitlines() if line.strip()]
TOP_TIER = re.compile("opus|fable|mythos", re.I)
MARKER = "**Exempt: the work-orchestrator helpers**"
RULE = re.compile(r"^##\s.*ask before launching", re.I)

def report(status, what):
    print(f"{status}\t{what}")

def backup(path):
    rel = os.path.relpath(path, home) if path.startswith(home) else path.lstrip("/")
    target = os.path.join(backup_root, rel)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    shutil.copy2(path, target)

def write(path, text):
    if dry_run:
        return
    if os.path.exists(path):
        backup(path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="") as handle:
        handle.write(text)

def eol_of(text):
    return "\r\n" if "\r\n" in text else "\n"

def is_ours(hook, script):
    return script in str(hook.get("command", ""))

def merge_settings():
    exists = os.path.exists(settings_path)
    text = open(settings_path, encoding="utf-8").read() if exists else ""
    settings = json.loads(text) if text.strip() else {}
    eol = eol_of(text) if text else "\n"
    changes = []
    if not uninstall:
        env = settings.setdefault("env", {})
        if "CLAUDE_CODE_SUBAGENT_MODEL_FORCE" in env:
            del env["CLAUDE_CODE_SUBAGENT_MODEL_FORCE"]
            changes.append("removed CLAUDE_CODE_SUBAGENT_MODEL_FORCE")
        model = env.get("CLAUDE_CODE_SUBAGENT_MODEL")
        if not model or TOP_TIER.search(model):
            env["CLAUDE_CODE_SUBAGENT_MODEL"] = "claude-sonnet-5-5"
            changes.append("set CLAUDE_CODE_SUBAGENT_MODEL to claude-sonnet-5-5")
    for event, matcher, command, timeout, script in hooks:
        entries = settings.get("hooks", {}).get(event, [])
        desired = {"matcher": matcher, "hooks": [{"type": "command", "command": command, "timeout": int(timeout)}]}
        ours = [entry for entry in entries if any(is_ours(hook, script) for hook in entry.get("hooks", []))]
        if (uninstall and not ours) or (not uninstall and ours == [desired]):
            continue
        kept = []
        for entry in entries:
            entry_hooks = entry.get("hooks", [])
            rest = [hook for hook in entry_hooks if not is_ours(hook, script)]
            if len(rest) == len(entry_hooks):
                kept.append(entry)
            elif rest:
                kept.append({**entry, "hooks": rest})
        if not uninstall:
            kept.append(desired)
        changes.append(f"{'removed' if uninstall else 'set'} the {script} {event} hook")
        if kept:
            settings.setdefault("hooks", {})[event] = kept
        else:
            settings["hooks"].pop(event, None)
            if not settings["hooks"]:
                del settings["hooks"]
    if changes:
        report("updated", f"{settings_path} — " + "; ".join(changes))
        write(settings_path, json.dumps(settings, indent=2, ensure_ascii=False).replace("\n", eol) + eol)
    else:
        report("unchanged", settings_path)

def exemption():
    names = [f"`{name}`" for name in helpers]
    listed = ", ".join(names[:-1]) + " and " + names[-1] if len(names) > 1 else names[0]
    text = (f"{MARKER} — {listed} in `~/.claude/agents/`. They run on their declared model and effort with "
            "their output caps; use them without asking. Any other agent, or a change to these definitions, "
            "still needs the plan table and a yes.")
    return textwrap.wrap(text, width=100, break_long_words=False, break_on_hyphens=False)

def edit_instructions():
    if not os.path.exists(claude_md):
        report("unchanged", f"{claude_md} — not present")
        return
    text = open(claude_md, encoding="utf-8").read()
    eol = eol_of(text)
    lines = text.split(eol) if eol == "\r\n" else text.split("\n")
    start = next((i for i, line in enumerate(lines) if line.startswith(MARKER)), None)
    if start is not None:
        end = start
        while end < len(lines) and lines[end].strip():
            end += 1
        if uninstall:
            first = start - 1 if start > 0 and not lines[start - 1].strip() else start
            del lines[first:end]
            action = "removed the helpers' exemption"
        else:
            if lines[start:end] == exemption():
                report("unchanged", f"{claude_md} — exemption already present")
                return
            lines[start:end] = exemption()
            action = "updated the helpers' exemption"
    elif uninstall or not helpers:
        report("unchanged", f"{claude_md} — no exemption to remove")
        return
    else:
        heading = next((i for i, line in enumerate(lines) if RULE.match(line)), None)
        if heading is None:
            report("unchanged", f"{claude_md} — no ask-before-subagents rule found")
            return
        end = heading + 1
        while end < len(lines) and not lines[end].strip():
            end += 1
        while end < len(lines) and lines[end].strip():
            end += 1
        lines[end:end] = [""] + exemption()
        action = "added the helpers' exemption to the ask-before-subagents rule"
    report("updated", f"{claude_md} — {action}")
    write(claude_md, eol.join(lines))

merge_settings()
edit_instructions()
PYTHON
)"
  while IFS=$'\t' read -r status what; do
    [ -n "${status:-}" ] && report "$status" "$what"
  done <<< "$RESULT"
else
  report manual "$SETTINGS — python3 not found, so it was not edited. Merge this in by hand:"
  echo '      env: remove CLAUDE_CODE_SUBAGENT_MODEL_FORCE; set CLAUDE_CODE_SUBAGENT_MODEL to "claude-sonnet-5-5"'
  while IFS=$'\t' read -r event matcher command timeout script; do
    [ -n "${event:-}" ] && echo "      hooks.$event: { \"matcher\": \"$matcher\", \"hooks\": [ { \"type\": \"command\", \"command\": \"${command//\"/\\\"}\", \"timeout\": $timeout } ] }"
  done <<< "$HOOK_SPEC"
  report manual "$CONFIG/CLAUDE.md — if it asks before every subagent, exempt the helpers: ${HELPER_NAMES[*]}"
fi

echo
if [ "$DRY_RUN" = 1 ]; then
  echo "Dry run: nothing was written."
elif [ "$CHANGED" = 1 ]; then
  echo "Done. Replaced and removed files are backed up in $BACKUP."
  echo "Start a new Claude Code session so the helpers, hooks and settings load."
else
  echo "Already up to date; nothing changed."
fi
[ "$MANUAL" = 1 ] && echo "Some steps need doing by hand — see 'manual' above."
exit 0
