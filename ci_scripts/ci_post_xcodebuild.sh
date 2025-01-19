#!/bin/bash

set -e

echo "Running post-xcodebuild script..."

# Navigate to repository root (parent of ci_scripts)
cd "$(dirname "$0")/.."

# Print build status
echo "Build exit code: $CI_XCODEBUILD_EXIT_CODE"

# Print derived data contents
echo "DerivedData contents:"
ls -la /Volumes/workspace/DerivedData || true

# Check build archive
if [ ! -d "/Volumes/workspace/build.xcarchive" ]; then
    echo "Error: Build archive not found! Build failed with exit code: $CI_XCODEBUILD_EXIT_CODE"
    # Print more debug info
    echo "Workspace contents:"
    ls -la /Volumes/workspace
    exit 1
fi

echo "Build archive contents:"
ls -la /Volumes/workspace/build.xcarchive

echo "Post-build tasks completed successfully"
