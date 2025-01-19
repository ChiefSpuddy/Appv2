#!/bin/bash

# Exit if any command fails
set -e

echo "Running pre-xcodebuild script..."

# Debug: Print current directory and environment
echo "Current working directory: $(pwd)"
echo "FLUTTER_ROOT: $HOME/flutter"

# Make sure we're using the right Flutter version
export PATH="$PATH:$HOME/flutter/bin"
flutter --version

# Additional iOS build setup
cd ios
echo "Updating iOS build settings..."

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

# Return to project root
cd ..

echo "Pre-build configuration completed"
