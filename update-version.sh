#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: ./update-version.sh <new-version>"
    exit 1
fi

NEW_VERSION=$1

# Update version file
echo "$NEW_VERSION" > version.txt

# Update cluster configuration
sed -i "s/v[0-9]\+\.[0-9]\+\.[0-9]\+/v${NEW_VERSION}/g" clusterConfiguration.yaml

git add version.txt clusterConfiguration.yaml
git commit -m "chore: update Kind version to ${NEW_VERSION}"
git tag "v${NEW_VERSION}"
git push origin main --tags
