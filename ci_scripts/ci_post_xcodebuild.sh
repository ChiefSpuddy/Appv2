#!/bin/bash

# Exit if any command fails
set -e

echo "Running post-xcodebuild script..."

# Navigate to repository root (parent of ci_scripts)
cd "$(dirname "$0")/.."

# Verify the build archive exists
if [ ! -d "/Volumes/workspace/build.xcarchive" ]; then
    echo "Error: Build archive not found!"
    exit 1
fi

# Print build archive contents
echo "Build archive contents:"
ls -la /Volumes/workspace/build.xcarchive

echo "Post-build tasks completed successfully"
