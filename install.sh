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
REQUESTED=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help)
      echo "Usage: ./install.sh [--dry-run] [--uninstall] [skill ...]"
      echo "  Installs the named skills - every skill in this repository when none is named - for"
      echo "  Claude Code and any other agent tool found. A skill that another one links into is"
      echo "  installed with it."
      echo "  --uninstall removes the named skills - every one of them that is installed when none is"
      echo "  named."
      echo "  --dry-run shows the plan and writes nothing."
      exit 0
      ;;
    -*) echo "Unknown option: $arg (see --help)"; exit 2 ;;
    *)
      IFS=',' read -r -a names <<< "$arg"
      for name in ${names[@]+"${names[@]}"}; do
        name="${name%/}"
        [ -n "$name" ] && REQUESTED+=("$name")
      done
      ;;
  esac
done

CONFIG="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
BACKUP="$CONFIG/backups/spec-skills/$(date +%Y%m%d-%H%M%S)"
CHANGED=0

report() {
  printf '  %-9s %s\n' "$1" "$2"
  case "$1" in added|updated|removed) CHANGED=1 ;; esac
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

unsync_skill() {
  local dest="$1" file
  [ -d "$dest" ] || return
  while IFS= read -r file; do
    remove "$file"
  done < <(find "$dest" -type f | sort)
  [ "$DRY_RUN" = 1 ] || rm -rf "$dest"
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

in_list() {
  local item="$1" each
  shift
  for each in "$@"; do [ "$each" = "$item" ] && return 0; done
  return 1
}

links_of() {
  local found name
  found="$(grep -rhoE '\.\./[A-Za-z0-9._-]+/' "$REPO/$1" 2>/dev/null | sort -u)"
  for name in $found; do
    name="${name#../}"
    name="${name%/}"
    [ "$name" != "$1" ] && in_list "$name" "${SKILLS[@]}" && echo "$name"
  done
}

for name in ${REQUESTED[@]+"${REQUESTED[@]}"}; do
  if ! in_list "$name" "${SKILLS[@]}"; then
    echo "Unknown skill: $name. Skills in this repository: ${SKILLS[*]}"
    exit 2
  fi
done

if [ "${#REQUESTED[@]}" -eq 0 ]; then
  SELECTED=("${SKILLS[@]}")
else
  SELECTED=("${REQUESTED[@]}")
fi

if [ "$UNINSTALL" = 1 ]; then
  CANDIDATES=("$CONFIG/skills" "$HOME/.agents/skills" "$HOME/.copilot/skills")
else
  CANDIDATES=("$CONFIG/skills")
  { [ -d "$HOME/.codex" ] || [ -d "$HOME/.cursor" ] || [ -d "$HOME/.gemini" ]; } && CANDIDATES+=("$HOME/.agents/skills")
  [ -d "$HOME/.copilot" ] && CANDIDATES+=("$HOME/.copilot/skills")
fi

NOTES=()
if [ "$UNINSTALL" = 1 ]; then
  for skill in "${SKILLS[@]}"; do
    in_list "$skill" "${SELECTED[@]}" && continue
    for target in "${CANDIDATES[@]}"; do
      same_dir "$REPO" "$target" && continue
      [ -f "$target/$skill/SKILL.md" ] || continue
      for needed in $(links_of "$skill"); do
        if in_list "$needed" "${SELECTED[@]}"; then
          echo "$skill in $target links into $needed, so $needed stays. Uninstall $skill with it, or leave $needed out. Nothing was changed."
          exit 1
        fi
      done
    done
  done
else
  index=0
  while [ "$index" -lt "${#SELECTED[@]}" ]; do
    for needed in $(links_of "${SELECTED[$index]}"); do
      if ! in_list "$needed" "${SELECTED[@]}"; then
        SELECTED+=("$needed")
        NOTES+=("$needed is included: ${SELECTED[$index]} links into it")
      fi
    done
    index=$((index + 1))
  done
fi

if [ "$UNINSTALL" = 1 ]; then MODE=uninstall; else MODE=install; fi
if [ "$DRY_RUN" = 1 ]; then echo "spec-skills $MODE — dry run, nothing written ($CONFIG)"; else echo "spec-skills $MODE ($CONFIG)"; fi

echo "Skills: ${SELECTED[*]}"
for note in ${NOTES[@]+"${NOTES[@]}"}; do
  echo "  $note"
done
for target in "${CANDIDATES[@]}"; do
  [ "$UNINSTALL" = 1 ] && [ ! -d "$target" ] && continue
  if same_dir "$REPO" "$target"; then
    report skipped "$target — this repository is that folder; a git pull keeps it current"
    continue
  fi
  for skill in "${SELECTED[@]}"; do
    if [ -L "$target/$skill" ]; then
      report skipped "$target/$skill — a link, left as it is"
      continue
    fi
    if [ "$UNINSTALL" = 1 ]; then unsync_skill "$target/$skill"; else sync_skill "$REPO/$skill" "$target/$skill"; fi
  done
done

echo
if [ "$DRY_RUN" = 1 ]; then
  echo "Dry run: nothing was written."
elif [ "$CHANGED" = 1 ]; then
  echo "Done. Replaced and removed files are backed up in $BACKUP."
  echo "Start a new session in your agent tool so the skills load."
else
  echo "Already up to date; nothing changed."
fi
exit 0
