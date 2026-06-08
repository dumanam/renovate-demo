#!/bin/bash
# ============================================================
# Renovate Local Demo Runner
# ============================================================
# Usage:
#   chmod +x run-renovate.sh
#   ./run-renovate.sh                  → dry run (safe, no PRs)
#   ./run-renovate.sh --live           → real run (opens actual PRs)
# ============================================================

GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_REPO="${GITHUB_REPO:-}"   # format: your-username/renovate-demo

if [ -z "$GITHUB_TOKEN" ]; then
  echo "ERROR: GITHUB_TOKEN env var is not set."
  echo "  export GITHUB_TOKEN=<your-github-pat>"
  exit 1
fi

if [ -z "$GITHUB_REPO" ]; then
  echo "ERROR: GITHUB_REPO env var is not set."
  echo "  export GITHUB_REPO=<your-github-username>/renovate-demo"
  exit 1
fi

DRY_RUN="--dry-run=full"
if [ "$1" == "--live" ]; then
  DRY_RUN=""
  echo ">>> LIVE MODE — Renovate will open real PRs on $GITHUB_REPO"
else
  echo ">>> DRY RUN MODE — No PRs will be created. Pass --live to create real PRs."
fi

echo ""
echo "Running Renovate against: $GITHUB_REPO"
echo "-------------------------------------------"

docker run --rm \
  -e RENOVATE_TOKEN="$GITHUB_TOKEN" \
  -e LOG_LEVEL=debug \
  renovate/renovate \
    --platform=github \
    $DRY_RUN \
    "$GITHUB_REPO"
