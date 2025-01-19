#!/bin/bash

# Exit if any command fails
set -e

echo "Running pre-xcodebuild script..."

# Navigate to repository root (parent of ci_scripts)
cd "$(dirname "$0")/.."
echo "Changed to repository root: $(pwd)"

# Debug: Print environment
echo "FLUTTER_ROOT: $HOME/flutter"
echo "Directory contents:"
ls -la

# Make sure we're using the right Flutter version
export PATH="$PATH:$HOME/flutter/bin"
flutter --version

# Verify iOS directory exists
if [ ! -d "ios" ]; then
    echo "Error: iOS directory not found!"
    echo "Current directory contents:"
    ls -la
    exit 1
fi

# Additional iOS build setup
echo "iOS directory found, updating build settings..."
cd ios

# Debug: Show iOS directory contents
echo "iOS directory contents:"
ls -la

# Update build settings
xcrun xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="2LPDHJ2TD4" \
    CODE_SIGN_STYLE="Automatic" \
    CODE_SIGN_IDENTITY="-" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    -showBuildSettings

echo "Pre-build configuration completed"
