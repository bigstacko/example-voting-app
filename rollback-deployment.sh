#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
DEPLOY_FILE="k8s/vote-deployment.yaml"
BRANCH="main"

# --- Ensure file exists ---
if [ ! -f "$DEPLOY_FILE" ]; then
  echo "❌ Deployment file $DEPLOY_FILE not found!"
  exit 1
fi

# --- Get current tag from working file ---
CURRENT_TAG=$(grep "image: stacko/vote-app:" "$DEPLOY_FILE" | sed -E 's/.*:([0-9]+).*/\1/')

# --- Get previous tag from one commit ago ---
if git rev-parse HEAD~1 >/dev/null 2>&1; then
  PREVIOUS_TAG=$(git show HEAD~1:$DEPLOY_FILE | grep "image: stacko/vote-app:" | sed -E 's/.*:([0-9]+).*/\1/')
else
  echo "❌ No previous commit found — cannot roll back."
  exit 0
fi

# --- Safety check ---
if [ -z "$CURRENT_TAG" ] || [ -z "$PREVIOUS_TAG" ]; then
  echo "❌ Could not determine current or previous tag."
  exit 1
fi

if [ "$CURRENT_TAG" == "$PREVIOUS_TAG" ]; then
  echo "ℹ️ Current and previous tags are the same ($CURRENT_TAG). Nothing to roll back."
  exit 0
fi

# --- Perform rollback ---
echo "🔄 Rolling back from $CURRENT_TAG → $PREVIOUS_TAG"
sed -i.bak "s|:$CURRENT_TAG|:$PREVIOUS_TAG|" "$DEPLOY_FILE"
rm -f "$DEPLOY_FILE.bak"

# --- Commit and push ---
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add "$DEPLOY_FILE"
git commit -m "rollback: revert image from $CURRENT_TAG to $PREVIOUS_TAG"
git push origin "$BRANCH"

echo "✅ Rolled back deployment to $PREVIOUS_TAG"
