#!/bin/bash

# Exit if any command fails
set -e

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
    
    # Create symbolic link for workspace at repository root
    if [ -d "ios/Runner.xcworkspace" ] && [ ! -d "Runner.xcworkspace" ]; then
        echo "Creating symbolic link for Runner.xcworkspace..."
        ln -s ios/Runner.xcworkspace Runner.xcworkspace
    fi
    
    # Clean pods first
    cd ios
    rm -rf Pods
    rm -f Podfile.lock
    
    # Install pods
    flutter clean
    flutter pub get
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
