#!/bin/sh
# Copy skills from fulcradynamics/agent-skills into the fulcra plugin, and
# record the commit they came from in skills.lock.
#
#   scripts/sync-skills.sh            refresh from agent-skills' main
#   scripts/sync-skills.sh <ref>      refresh from a branch, tag or commit
#   scripts/sync-skills.sh --check    fail if the copies differ from skills.lock
#
# skills.lock lists one skill per line: "<name> <commit>". A skill edited only
# here is overwritten by the next sync: change it in agent-skills instead.
set -eu

REPO=https://github.com/fulcradynamics/agent-skills
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=$ROOT/plugins/fulcra/skills
LOCK=$ROOT/skills.lock

fetch() { # <commit> <dir>: unpack agent-skills at <commit> into <dir>
  curl -fsSL "https://codeload.github.com/fulcradynamics/agent-skills/tar.gz/$1" |
    tar -xz -C "$2" --strip-components=1
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [ "${1:-}" = "--check" ]; then
  status=0
  while read -r name commit; do
    mkdir -p "$TMP/$commit"
    [ -d "$TMP/$commit/skills" ] || fetch "$commit" "$TMP/$commit"
    if ! diff -r "$TMP/$commit/skills/$name" "$DEST/$name" >/dev/null; then
      echo "$name differs from agent-skills at $commit; run scripts/sync-skills.sh" >&2
      status=1
    fi
  done < "$LOCK"
  exit $status
fi

ref=${1:-main}
commit=$(git ls-remote "$REPO" "$ref" | awk 'NR == 1 { print $1 }')
[ -n "$commit" ] || commit=$ref # a commit hash isn't listed by ls-remote
fetch "$commit" "$TMP"

: > "$LOCK.new"
while read -r name _; do
  [ -d "$TMP/skills/$name" ] || { echo "agent-skills has no skill $name at $commit" >&2; exit 1; }
  rm -rf "${DEST:?}/$name"
  cp -R "$TMP/skills/$name" "$DEST/$name"
  echo "$name $commit" >> "$LOCK.new"
  echo "synced $name at $commit"
done < "$LOCK"
mv "$LOCK.new" "$LOCK"
