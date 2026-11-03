#!/usr/bin/env bash
# Sync Forgejo's source tree to GitHub main without rewriting GitHub history.
set -euo pipefail

UPSTREAM_URL="https://git.eden-emu.dev/Franseven/PokeDinner-a-Eglantine-Fork.git"
UPSTREAM_BRANCH="master"
STATUS_FILE=".github/sync/upstream-head.sha"
CONTROL_WORKFLOW=".github/workflows/auto-sync-release.yml"
CONTROL_SCRIPT=".github/scripts/sync-upstream.sh"

git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
git remote add forgejo "$UPSTREAM_URL" 2>/dev/null || git remote set-url forgejo "$UPSTREAM_URL"
git -c http.version=HTTP/1.1 fetch --no-tags --depth=1 forgejo "refs/heads/${UPSTREAM_BRANCH}"
new_sha="$(git rev-parse FETCH_HEAD)"
old_sha="$(cat "$STATUS_FILE" 2>/dev/null || true)"
echo "source_sha=$new_sha" >> "$GITHUB_OUTPUT"

if [[ "$new_sha" == "$old_sha" ]]; then
  echo "changed=false" >> "$GITHUB_OUTPUT"
  echo "mirror_sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
  echo "Upstream unchanged ($new_sha), skipping mirror and builds."
  exit 0
fi

overlay="$(mktemp -d)"
trap 'rm -rf "$overlay"' EXIT
mkdir -p "$overlay/.github/workflows" "$overlay/.github/scripts"
cp "$CONTROL_WORKFLOW" "$overlay/$CONTROL_WORKFLOW"
cp "$CONTROL_SCRIPT" "$overlay/$CONTROL_SCRIPT"

# The read-tree operation changes the index and working tree, but not HEAD.
# It produces normal descendant commits and never force-pushes the local branch.
git read-tree --reset -u FETCH_HEAD
mkdir -p ".github/workflows" ".github/scripts" ".github/sync"
cp "$overlay/$CONTROL_WORKFLOW" "$CONTROL_WORKFLOW"
cp "$overlay/$CONTROL_SCRIPT" "$CONTROL_SCRIPT"
printf '%s\n' "$new_sha" > "$STATUS_FILE"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "chore(mirror): sync Forgejo master (${new_sha:0:12})"
  git push origin HEAD:main
fi
echo "changed=true" >> "$GITHUB_OUTPUT"
echo "mirror_sha=$(git rev-parse HEAD)" >> "$GITHUB_OUTPUT"
echo "Mirrored Forgejo master $new_sha to $(git rev-parse HEAD)."
