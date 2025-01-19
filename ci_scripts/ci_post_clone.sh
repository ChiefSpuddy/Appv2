#!/bin/bash

# Exit if any command fails
set -e
set -x

echo "Running post-clone script..."

# Debug: Print current directory
echo "Current working directory: $(pwd)"

# Navigate to repository root (parent of ci_scripts)
cd "$(dirname "$0")/.."
echo "Changed to repository root: $(pwd)"

# Debug: Show directory structure
echo "Directory structure before setup:"
ls -la
ls -la ios/ || echo "No ios directory found"

# Get Flutter
git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Precache iOS artifacts
echo "Precaching iOS artifacts..."
flutter precache --ios

# Debug: Verify Flutter installation
echo "Flutter version:"
flutter --version

# Install Flutter dependencies
flutter pub get

# Check if iOS directory exists
if [ -d "ios" ]; then
    echo "iOS directory found, installing pods..."
    cd ios
    rm -rf Pods
    rm -f Podfile.lock
    cd ..
    flutter clean
    flutter pub get
    cd ios
    pod install --repo-update
    cd ..
else
    echo "Error: iOS directory not found"
    exit 1
fi

# Debug: Show final directory structure
echo "Final directory structure:"
ls -la
ls -la ios/

# Make sure Flutter is ready for iOS builds
flutter doctor -v

# Debug: List important directories
echo "Repository contents:"
ls -la

# Install CocoaPods if needed
if ! command -v pod &> /dev/null; then
    sudo gem install cocoapods
fi

# Setup iOS build
cd ios
pod cache clean --all
pod deintegrate
pod repo update
pod install --verbose

# Create workspace symlink at root
cd ..
ln -s ios/Runner.xcworkspace Runner.xcworkspace

echo "Post-clone setup completed"
