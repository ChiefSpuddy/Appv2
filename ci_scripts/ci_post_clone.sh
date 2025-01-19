#!/bin/bash

# Exit if any command fails
set -e

# Debug: Print current directory
echo "Current working directory: $(pwd)"

# Navigate to repository root (parent of ci_scripts)
cd "$(dirname "$0")/.."
echo "Changed to repository root: $(pwd)"

# Get Flutter
git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Debug: Verify Flutter installation
echo "Flutter version:"
flutter --version

# Install Flutter dependencies
flutter pub get

# Check if iOS directory exists
if [ -d "ios" ]; then
    echo "iOS directory found, installing pods..."
    cd ios
    pod install
    cd ..
else
    echo "Warning: iOS directory not found"
fi

# Make sure Flutter is ready for iOS builds
flutter doctor -v

# Debug: List important directories
echo "Repository contents:"
ls -la
