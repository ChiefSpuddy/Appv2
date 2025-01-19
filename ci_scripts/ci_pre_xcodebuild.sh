#!/bin/bash

# Exit if any command fails
set -e
set -x  # Enable debug output

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

# Ensure we're in the ios directory
cd ios || exit 1

# Clean everything first
rm -rf Pods build Runner.xcworkspace
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Setup pods
pod cache clean --all
pod deintegrate
pod repo update
pod install  # This will recreate Runner.xcworkspace

# Verify workspace exists
if [ ! -d "Runner.xcworkspace" ]; then
    echo "Error: Runner.xcworkspace was not created by pod install"
    exit 1
fi

# Now that workspace exists, run xcodebuild
xcrun xcodebuild clean -workspace Runner.xcworkspace -scheme Runner
xcrun xcodebuild -workspace Runner.xcworkspace \
    -scheme Runner \
    -configuration Release \
    -allowProvisioningUpdates \
    DEVELOPMENT_TEAM="2LPDHJ2TD4" \
    CODE_SIGN_STYLE="Automatic" \
    CODE_SIGN_IDENTITY="-" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    ARCHS="arm64" \
    ONLY_ACTIVE_ARCH=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    DEAD_CODE_STRIPPING=NO \
    STRIP_INSTALLED_PRODUCT=NO \
    COPY_PHASE_STRIP=NO \
    -showBuildSettings

echo "Pre-build configuration completed"
