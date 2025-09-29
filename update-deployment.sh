#This script updates image tag based on the new image build number
#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
IMAGE="stacko/vote-app"
DEPLOY_FILE="k8s-specifications/vote-deployment.yaml"   # adjust to your manifest file
BRANCH="main"

# --- Ensure a new tag was passed in ---
if [ $# -ne 1 ]; then
  echo "Usage: $0 <new-tag>"
  exit 1
fi
NEW_TAG=$1

# --- Ensure file exists ---
if [ ! -f "$DEPLOY_FILE" ]; then
  echo "❌ Deployment file $DEPLOY_FILE not found!"
  exit 1
fi

# --- Find current tag ---
CURRENT_TAG=$(grep "image: $IMAGE:" "$DEPLOY_FILE" | sed "s|.*$IMAGE:||")

# --- Compare and only update if needed ---
if [ "$CURRENT_TAG" == "$NEW_TAG" ]; then
  echo "ℹ️ Already running $IMAGE:$NEW_TAG — nothing to do."
  exit 0
fi

# --- Update manifest with new tag ---
echo "🔄 Updating $DEPLOY_FILE: $CURRENT_TAG → $NEW_TAG"
sed -i.bak "s|image: $IMAGE:$CURRENT_TAG|image: $IMAGE:$NEW_TAG|" "$DEPLOY_FILE"
rm -f "$DEPLOY_FILE.bak"

# --- Commit and push ---
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"
git add "$DEPLOY_FILE"
git commit -m "chore: bump $IMAGE from $CURRENT_TAG to $NEW_TAG"
git push origin "$BRANCH"

echo "✅ Updated $DEPLOY_FILE with $IMAGE:$NEW_TAG and pushed to $BRANCH"

