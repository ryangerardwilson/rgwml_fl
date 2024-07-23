#!/bin/bash

# Exit on any error
set -e

# Function to increment version number
increment_version() {
    local old_version=$1
    local major=$(echo $old_version | cut -d. -f1)
    local minor=$(echo $old_version | cut -d. -f2)
    local patch=$(echo $old_version | cut -d. -f3)

    # Increment patch version
    patch=$((patch + 1))

    echo "$major.$minor.$patch"
}

# Read the current version from pubspec.yaml
current_version=$(grep ^version pubspec.yaml | sed 's/version: //')

# Ensure the version was found
if [ -z "$current_version" ]; then
    echo "Error: Could not find the version in pubspec.yaml"
    exit 1
fi

echo "Current version: $current_version"

# Increment the version
new_version=$(increment_version $current_version)
echo "New version: $new_version"

# Update the version in pubspec.yaml
sed -i "s/^version: .*/version: $new_version/" pubspec.yaml

# Add files, commit and create tag for the new version
git add pubspec.yaml
git commit -m "Bump version to $new_version"
git tag $new_version

# Publish the package
dart pub publish --force

echo "Successfully published version $new_version to pub.dev"

