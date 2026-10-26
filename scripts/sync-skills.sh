#!/bin/sh
# Copy skills from fulcradynamics/agent-skills into the fulcra plugin, and
# record the commit they came from in skills.lock.
#
#   scripts/sync-skills.sh            refresh from agent-skills' main
#   scripts/sync-skills.sh <ref>      refresh from a branch, tag or commit
#   scripts/sync-skills.sh --check    fail if the copies differ from skills.lock
#
# skills.lock lists one skill per line: "<name> <commit>". Blank lines and lines
# starting with # are ignored. To add a skill, add a line with its name (the
# commit can be anything, such as "main") and run a sync, which pins it. A skill
# edited only here is overwritten by the next sync: change it in agent-skills.
#
# A sync changes nothing unless every skill in the lockfile can be fetched and
# installed; the lockfile is rewritten only after all of them are in place.
set -eu
export LC_ALL=C # so [a-z] in patterns means lowercase only

REPO=https://github.com/fulcradynamics/agent-skills
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=$ROOT/plugins/fulcra/skills
LOCK=$ROOT/skills.lock

die() { echo "sync-skills: $*" >&2; exit 1; }

fetch() { # <commit> <dir>: unpack agent-skills at <commit> into <dir>
  mkdir -p "$2"
  curl -fsSL "https://codeload.github.com/fulcradynamics/agent-skills/tar.gz/$1" |
    tar -xz -C "$2" --strip-components=1 || die "couldn't fetch agent-skills at $1"
}

# The lockfile's entries as "<name> <commit>" lines, checked: no malformed
# names, no duplicates. Skips blank and # lines, and reads a last line that has
# no trailing newline.
entries() {
  [ -f "$LOCK" ] || die "no $LOCK"
  seen=" "
  while read -r name commit _ || [ -n "${name:-}" ]; do
    case ${name:-} in "" | \#*) continue ;; esac
    case $name in
      *[!a-z0-9-]* | -* | *-) die "skills.lock: invalid skill name '$name'" ;;
    esac
    case $seen in *" $name "*) die "skills.lock: $name is listed twice" ;; esac
    seen="$seen$name "
    echo "$name ${commit:-}"
  done < "$LOCK"
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
entries > "$TMP/entries"
if [ ! -s "$TMP/entries" ]; then
  echo "sync-skills: skills.lock lists no skills; nothing to sync"
  exit 0
fi

if [ "${1:-}" = "--check" ]; then
  status=0
  while read -r name commit; do
    case $commit in
      "" | *[!0-9a-f]*) die "skills.lock: $name isn't pinned to a commit ('$commit'); run scripts/sync-skills.sh" ;;
    esac
    [ ${#commit} -eq 40 ] || die "skills.lock: $name isn't pinned to a full commit hash ('$commit')"
    [ -d "$TMP/$commit/skills" ] || fetch "$commit" "$TMP/$commit"
    if [ ! -d "$TMP/$commit/skills/$name" ]; then
      echo "agent-skills has no skill $name at $commit" >&2
      status=1
    elif ! diff -r "$TMP/$commit/skills/$name" "$DEST/$name" >/dev/null 2>&1; then
      echo "$name differs from agent-skills at $commit; run scripts/sync-skills.sh" >&2
      status=1
    fi
  done < "$TMP/entries"
  exit $status
fi

# Resolve the ref to the full commit hash that gets pinned.
ref=${1:-main}
commit=$(curl -fsSL -H "Accept: application/vnd.github.sha" \
  "https://api.github.com/repos/fulcradynamics/agent-skills/commits/$ref") ||
  die "couldn't resolve '$ref' to an agent-skills commit"
case $commit in *[!0-9a-f]*) die "couldn't resolve '$ref' to an agent-skills commit" ;; esac
[ ${#commit} -eq 40 ] || die "couldn't resolve '$ref' to an agent-skills commit"
fetch "$commit" "$TMP/src"

# 1. Stage every skill, so a missing one stops the sync before anything changes.
mkdir "$TMP/stage" "$TMP/old" "$TMP/swapped"
while read -r name _; do
  [ -d "$TMP/src/skills/$name" ] || die "agent-skills has no skill $name at $commit; nothing changed"
  cp -R "$TMP/src/skills/$name" "$TMP/stage/$name"
done < "$TMP/entries"

# 2. Swap them in, keeping the old copies until every swap has worked.
restore() {
  for marker in "$TMP"/swapped/*; do
    [ -e "$marker" ] || continue
    name=$(basename "$marker")
    rm -rf "${DEST:?}/$name"
    if [ -d "$TMP/old/$name" ]; then mv "$TMP/old/$name" "$DEST/$name"; fi
  done
  die "replacing $1 failed; restored the skills as they were"
}
while read -r name _; do
  if [ -e "$DEST/$name" ]; then mv "$DEST/$name" "$TMP/old/$name" || restore "$name"; fi
  touch "$TMP/swapped/$name" # from here, a restore puts the old copy back
  mv "$TMP/stage/$name" "$DEST/$name" || restore "$name"
done < "$TMP/entries"

# 3. Only now record the commit.
awk -v c="$commit" '{ print $1, c }' "$TMP/entries" > "$LOCK.new"
mv "$LOCK.new" "$LOCK"
awk -v c="$commit" '{ print "synced " $1 " at " c }' "$TMP/entries"
