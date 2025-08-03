#!/bin/bash

# Swiftcord DMG Builder Script
# This script builds Swiftcord in release mode and packages it into a DMG

set -e

echo "🚀 Starting Swiftcord DMG build process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "Swiftcord.xcodeproj/project.pbxproj" ]; then
    print_error "Please run this script from the Swiftcord project root directory"
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
rm -rf build/
rm -rf Swiftcord.xcarchive/
rm -rf Export/
rm -f Swiftcord*.dmg

# Create build directory
mkdir -p build

# Build the archive
print_status "Building Swiftcord archive..."
xcodebuild -project Swiftcord.xcodeproj \
    -scheme Swiftcord \
    -configuration Release \
    -archivePath Swiftcord.xcarchive \
    archive \
    COMPILER_INDEX_STORE_ENABLE=NO

if [ $? -ne 0 ]; then
    print_error "Archive build failed!"
    exit 1
fi

print_success "Archive built successfully!"

# Export the app
print_status "Exporting Swiftcord.app..."
xcodebuild -exportArchive \
    -archivePath Swiftcord.xcarchive \
    -exportPath Export \
    -exportOptionsPlist exportOptions.plist

if [ $? -ne 0 ]; then
    print_error "Export failed!"
    exit 1
fi

print_success "App exported successfully!"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    print_warning "create-dmg not found. Installing..."
    if command -v brew &> /dev/null; then
        brew install create-dmg
    else
        print_error "Please install create-dmg manually: brew install create-dmg"
        exit 1
    fi
fi

# Create DMG
print_status "Creating DMG..."
create-dmg \
    --volname "Swiftcord" \
    --volicon "Swiftcord/Assets.xcassets/AppIcon.appiconset/app-512.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Swiftcord.app" 175 120 \
    --hide-extension "Swiftcord.app" \
    --app-drop-link 425 120 \
    "Swiftcord.dmg" \
    "Export/"

if [ $? -ne 0 ]; then
    print_error "DMG creation failed!"
    exit 1
fi

print_success "DMG created successfully!"

# Get the DMG filename
DMG_FILE=$(ls Swiftcord*.dmg | head -n 1)

if [ -n "$DMG_FILE" ]; then
    print_success "🎉 Swiftcord DMG created: $DMG_FILE"
    print_status "File size: $(du -h "$DMG_FILE" | cut -f1)"
    print_status "Location: $(pwd)/$DMG_FILE"
else
    print_error "DMG file not found!"
    exit 1
fi

# Clean up build artifacts (optional)
read -p "Do you want to clean up build artifacts? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Cleaning up build artifacts..."
    rm -rf build/
    rm -rf Swiftcord.xcarchive/
    rm -rf Export/
    print_success "Cleanup completed!"
fi

print_success "🎊 Swiftcord DMG build process completed successfully!" 