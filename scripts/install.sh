#!/usr/bin/env bash
# Points each agent's user-level folders at this repo, so its instructions and
# skills apply in every repo. Run once per machine; after that, `git pull`
# updates everything, new skills included.
#
# An existing symlink is replaced. A real file or folder is left alone and
# reported, so a hand-made setup is never overwritten. Safe to rerun.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
claude=${CLAUDE_CONFIG_DIR:-$HOME/.claude}

# One row per agent: name, where it reads user-level instructions, where it
# reads user-level skills. Add a row to support another agent.
agents=(
  "claude $claude/CLAUDE.md $claude/skills"
)

skipped=0
link() {
  local target=$1 at=$2
  mkdir -p "$(dirname "$at")"
  if [[ -e $at && ! -L $at ]]; then
    echo "skipped $at: exists and isn't a symlink" >&2
    skipped=$((skipped + 1))
    return
  fi
  ln -sfn "$target" "$at"
  echo "$at -> $target"
}

for row in "${agents[@]}"; do
  read -r _ instructions skills <<<"$row"
  link "$root/global/CLAUDE.md" "$instructions"
  link "$root/skills" "$skills"
done

if ((skipped)); then
  echo "$skipped path(s) skipped; move them aside and rerun to link them" >&2
  exit 1
fi
