#This script rolls back deployment to previous stable version based on commit history
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

# --- Extract last 2 tags from Git history ---
TAGS=($(git log -p -n 10 -- "$DEPLOY_FILE" | grep "image:" | sed -E 's/.*:([0-9]+).*/\1/' | uniq | head -2))

if [ ${#TAGS[@]} -lt 2 ]; then
  echo "❌ Not enough history to roll back."
  exit 1
fi

CURRENT_TAG=${TAGS[0]}
PREVIOUS_TAG=${TAGS[1]}

# --- Replace current with previous ---
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

