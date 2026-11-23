#!/usr/bin/env bash
# Third-party skills, copied into skills/<name>/ at the commit pinned in
# vendor.lock.json, with each source's licence in licenses/.
#
#   scripts/vendor.sh             copy them (after editing the lock)
#   scripts/vendor.sh --check     fail if a copy differs from its pinned commit (CI)
#   scripts/vendor.sh --outdated  list the skills upstream has changed since the pin
#
# Editing your own skills never needs this. Needs git and jq.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
lock="$root/vendor.lock.json"
mode=${1:-sync}
own=$(jq -r '.skills[] | sub("^\\./skills/"; "")' "$root/.claude-plugin/plugin.json")

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
status=0

for source in $(jq -r 'keys[]' "$lock"); do
  repo=$(jq -r --arg s "$source" '.[$s].repo' "$lock")
  commit=$(jq -r --arg s "$source" '.[$s].commit' "$lock")
  paths=$(jq -r --arg s "$source" '.[$s].skills[]' "$lock")
  up="$tmp/$source"

  git init -q "$up"
  if [[ $mode == --outdated ]]; then
    git -C "$up" fetch -q --filter=blob:none "$repo" HEAD "$commit"
    head=$(git -C "$up" rev-parse FETCH_HEAD)
    # shellcheck disable=SC2086
    changed=$(git -C "$up" diff --name-only "$commit" "$head" -- $paths |
      while read -r file; do
        for p in $paths; do
          if [[ $file == "$p"/* ]]; then basename "$p"; fi
        done
      done | sort -u)
    if [[ -n $changed ]]; then
      echo "$source: changed upstream since ${commit:0:7} (now ${head:0:7}):"
      sed 's/^/  /' <<<"$changed"
    else
      echo "$source: up to date with ${head:0:7}"
    fi
    continue
  fi

  git -C "$up" fetch -q --depth 1 "$repo" "$commit"
  git -C "$up" checkout -q FETCH_HEAD
  for path in $paths; do
    name=$(basename "$path")
    if grep -qx "$name" <<<"$own"; then
      echo "$source/$path: skills/$name is one of this repo's own skills" >&2
      exit 1
    fi
    if [[ $mode == --check ]]; then
      if ! diff -r "$up/$path" "$root/skills/$name" >/dev/null 2>&1; then
        echo "skills/$name differs from $repo@${commit:0:7}; run scripts/vendor.sh" >&2
        status=1
      fi
    else
      rm -rf "${root:?}/skills/$name"
      cp -R "$up/$path" "$root/skills/$name"
    fi
  done
  if [[ $mode != --check ]]; then
    mkdir -p "$root/licenses"
    cp "$up/LICENSE" "$root/licenses/$source.txt"
    echo "$source: $(wc -w <<<"$paths") skills <- $repo@${commit:0:7}"
  fi
done

exit $status
