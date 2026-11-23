#!/usr/bin/env bash
# Links this repo's instructions and skills into each agent's user-level
# folders, so they apply in every repo.
#
#   scripts/install.sh               link into the current profile, and remember it
#   scripts/install.sh --no-skills   the same, minus the skills (and unlink any)
#   scripts/install.sh --remembered  relink every remembered profile
#
# See the README's Setup section.
set -euo pipefail
shopt -s nullglob

root=$(cd "$(dirname "$0")/.." && pwd)
remembered="$(git -C "$root" rev-parse --path-format=absolute --git-common-dir)/home-repo-targets"

# One row per agent: name, the variable that names its config folder, the
# default folder, its user-level instructions file, its skills folder.
# Supporting another agent is one more row.
agents=(
  "claude CLAUDE_CONFIG_DIR $HOME/.claude CLAUDE.md skills"
)

skipped=0
link() {
  local target=$1 at=$2
  if [[ -e $at && ! -L $at ]]; then
    echo "skipped $at: a real file or folder is in the way" >&2
    skipped=$((skipped + 1))
  elif [[ $(readlink "$at") != "$target" ]]; then
    ln -sfn "$target" "$at"
    echo "linked $at"
  fi
}

install_into() {
  local name=$1 dir=$2 with=$3 row n instructions skills file base
  for row in "${agents[@]}"; do
    read -r n _ _ instructions skills <<<"$row"
    [[ $n == "$name" ]] && break
  done
  mkdir -p "$dir/$skills"
  # CLAUDE.md under the agent's instructions name; the files it points to as is.
  for file in "$root"/global/*; do
    base=$(basename "$file")
    [[ $base == CLAUDE.md ]] && base=$instructions
    link "$file" "$dir/$base"
  done
  if [[ $with == skills ]]; then
    for skill in "$root"/skills/*/; do
      link "${skill%/}" "$dir/$skills/$(basename "$skill")"
    done
  fi
  # Links into this repo's skills/ whose skill is gone, or all of them without skills.
  for at in "$dir/$skills"/*; do
    if [[ -L $at && $(readlink "$at") == "$root/skills/"* && ($with != skills || ! -e $at) ]]; then
      rm "$at"
      echo "removed $at"
    fi
  done
}

if [[ ${1:-} == --remembered ]]; then
  [[ -f $remembered ]] || exit 0
  while read -r name dir with; do install_into "$name" "$dir" "${with:-skills}"; done <"$remembered"
else
  with=skills
  [[ ${1:-} == --no-skills ]] && with=no-skills
  for row in "${agents[@]}"; do
    read -r name var default _ _ <<<"$row"
    dir=${!var:-$default}
    install_into "$name" "$dir" "$with"
    # One line per profile; a rerun replaces its line.
    { [[ -f $remembered ]] && awk -v n="$name" -v d="$dir" '!($1 == n && $2 == d)' "$remembered"; echo "$name $dir $with"; } >"$remembered.new"
    mv "$remembered.new" "$remembered"
  done
  hooks=$(git -C "$root" rev-parse --path-format=absolute --git-path hooks)
  mkdir -p "$hooks"
  for hook in post-merge post-rewrite; do
    if [[ -e $hooks/$hook ]] && ! grep -q 'home-repo install' "$hooks/$hook"; then
      echo "skipped the $hook hook: one already exists; add \`$root/scripts/install.sh --remembered\` to it" >&2
      continue
    fi
    printf '#!/bin/sh\n# home-repo install: relink skills after a pull\nexec "%s/scripts/install.sh" --remembered\n' "$root" >"$hooks/$hook"
    chmod +x "$hooks/$hook"
  done
fi

if ((skipped)); then
  echo "$skipped path(s) skipped; move them aside and rerun to link them" >&2
  exit 1
fi
