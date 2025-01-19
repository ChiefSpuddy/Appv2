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

# Create archive directory with proper permissions
sudo mkdir -p /Volumes/workspace/build.xcarchive
sudo chmod 777 /Volumes/workspace/build.xcarchive

# Copy build artifacts if they exist
if [ -d "/Volumes/workspace/DerivedData/Build/Products/Release-iphoneos" ]; then
  echo "Copying build artifacts to archive..."
  sudo cp -R /Volumes/workspace/DerivedData/Build/Products/Release-iphoneos/* /Volumes/workspace/build.xcarchive/
  exit 0
else
  echo "Error: Build products directory not found!"
  ls -la /Volumes/workspace/DerivedData/Build/Products || true
  exit 1
fi

# Create archive directory if it doesn't exist
mkdir -p /Volumes/workspace/build.xcarchive

# Check build archive
if [ ! -d "/Volumes/workspace/build.xcarchive" ]; then
    echo "Error: Build archive not found! Build failed with exit code: $CI_XCODEBUILD_EXIT_CODE"
    # Print more debug info
    echo "Workspace contents:"
    ls -la /Volumes/workspace
    exit 1
fi

echo "Build archive contents:"
ls -la /Volumes/workspace/build.xcarchive || true

# Create archive directory if it doesn't exist
mkdir -p "${ARCHIVE_PATH}"

# Ensure archive is generated in the correct location
if [ -d "${BUILD_DIR}" ]; then
  cp -r "${BUILD_DIR}" "${ARCHIVE_PATH}"
  echo "Archive successfully created at ${ARCHIVE_PATH}"
  exit 0
else
  echo "Error: Build directory not found!"
  exit 1
fi

echo "Post-build tasks completed successfully"
exit 0
