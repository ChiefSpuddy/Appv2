#!/bin/bash

set -e

echo "Running post-xcodebuild script..."

# List of possible build paths
POSSIBLE_PATHS=(
  "/Volumes/workspace/DerivedData/Build/Products/Release-iphoneos"
  "/Volumes/workspace/DerivedData/Build/Intermediates.noindex/ArchiveIntermediates/Runner/BuildProductsPath/Release-iphoneos"
  "$(pwd)/build/ios/iphoneos"
)

# Create archive directory
mkdir -p /Volumes/workspace/build.xcarchive

# Try each possible path
for BUILD_PATH in "${POSSIBLE_PATHS[@]}"; do
  echo "Checking build path: $BUILD_PATH"
  if [ -d "$BUILD_PATH" ]; then
    echo "Found build products at: $BUILD_PATH"
    echo "Copying build artifacts to archive..."
    cp -R "$BUILD_PATH"/* /Volumes/workspace/build.xcarchive/
    exit 0
  fi
done

echo "Error: Could not find build products in any expected location!"
ls -la /Volumes/workspace/DerivedData/Build || true
exit 1
