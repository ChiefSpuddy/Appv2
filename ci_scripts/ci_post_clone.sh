#!/bin/bash

# Exit if any command fails
set -e

# Debug: Print current directory
echo "Current working directory: $(pwd)"

# Get Flutter
git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Debug: Verify Flutter installation
echo "Flutter version:"
flutter --version

# Install Flutter dependencies
flutter pub get

# Navigate to iOS directory and install pods
cd ios
pod install
cd ..

# Make sure Flutter is ready for iOS builds
flutter doctor -v

# Debug: List important directories
echo "Repository contents:"
ls -la
echo "iOS directory contents:"
ls -la ios/
