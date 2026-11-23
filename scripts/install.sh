#!/usr/bin/env bash
# Links this repo's instructions and skills into each agent's user-level
# folders, so they apply in every repo.
#
#   scripts/install.sh               link into the current profile, and remember it
#   scripts/install.sh --remembered  relink every remembered profile
#
# Run it once per profile, e.g. once as is and once with CLAUDE_CONFIG_DIR set.
# It also installs git hooks that run --remembered after every pull, so from
# then on `git pull` is the whole update: new skills get linked, and links to
# removed ones are deleted.
#
# Each skill is its own link and the skills folder stays a real folder, so
# whatever else lives there (claude.ai's synced/, local skills) is untouched
# and stays per profile. An existing link is replaced; a real file or folder
# in the way is reported and left alone. Safe to rerun.
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
  local name=$1 dir=$2 row n instructions skills
  for row in "${agents[@]}"; do
    read -r n _ _ instructions skills <<<"$row"
    [[ $n == "$name" ]] && break
  done
  mkdir -p "$dir/$skills"
  link "$root/global/CLAUDE.md" "$dir/$instructions"
  for skill in "$root"/skills/*/; do
    link "${skill%/}" "$dir/$skills/$(basename "$skill")"
  done
  # Links into this repo's skills/ whose skill is gone.
  for at in "$dir/$skills"/*; do
    if [[ -L $at && $(readlink "$at") == "$root/skills/"* && ! -e $at ]]; then
      rm "$at"
      echo "removed $at"
    fi
  done
}

if [[ ${1:-} == --remembered ]]; then
  [[ -f $remembered ]] || exit 0
  while read -r name dir; do install_into "$name" "$dir"; done <"$remembered"
else
  for row in "${agents[@]}"; do
    read -r name var default _ _ <<<"$row"
    dir=${!var:-$default}
    install_into "$name" "$dir"
    grep -qxF "$name $dir" "$remembered" 2>/dev/null || echo "$name $dir" >>"$remembered"
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
