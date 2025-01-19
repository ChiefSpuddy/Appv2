#!/bin/bash

set -e
set -x

echo "Running pre-xcodebuild script..."

# Navigate to repository root
cd "$(dirname "$0")/.."
REPO_ROOT=$(pwd)

# Ensure Flutter is available
export PATH="$PATH:$HOME/flutter/bin"
flutter --version

# Verify iOS directory exists
if [ ! -d "ios" ]; then
    echo "Error: iOS directory not found!"
    exit 1
fi

echo "Running flutter clean and pub get..."
flutter clean
flutter pub get

cd ios

# Clean everything first
rm -rf Pods build Runner.xcworkspace
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Setup pods
echo "Setting up CocoaPods..."
pod deintegrate
pod cache clean --all
pod repo update
pod install --verbose  # Verbose output for debugging

# Verify workspace exists
if [ ! -f "Runner.xcworkspace/contents.xcworkspacedata" ]; then
    echo "Error: Runner.xcworkspace was not created properly"
    echo "Current directory contents:"
    ls -la
    echo "Workspace directory contents:"
    ls -la Runner.xcworkspace || echo "Workspace directory does not exist"
    exit 1
fi

# Create symbolic link at repository root if needed
cd "$REPO_ROOT"
if [ ! -d "Runner.xcworkspace" ]; then
    ln -s ios/Runner.xcworkspace Runner.xcworkspace
fi

echo "Workspace setup completed successfully"
