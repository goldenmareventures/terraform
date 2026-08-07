#!/bin/bash
# scripts/release.sh

echo "📋 Changes since last release:"
echo ""
git log $(git describe --tags --abbrev=0)..HEAD --oneline
echo ""
echo ""
echo "📋 Pre-release checklist:"
echo "✓ All modules validated?"
echo "✓ Tested in at least one project?"
echo "✓ Any breaking changes? (Use major if yes)"
echo ""
read -p "Release type (major/minor/patch): " type

if [[ ! "$type" =~ ^(major|minor|patch)$ ]]; then
  echo "Invalid release type. Must be major, minor, or patch"
  exit 1
fi

npm run release:$type

echo ""
echo "✅ Release created! Next steps:"
echo "git push --follow-tags"