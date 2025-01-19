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

# Clean Pods and derived data
echo "Cleaning build artifacts..."
rm -rf ios/Pods ios/build ios/Runner.xcworkspace
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Reinstall pods
echo "Reinstalling pods..."
cd ios
pod cache clean --all
pod deintegrate
pod repo update
pod install --repo-update

# Configure build settings
echo "Configuring build settings..."
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
