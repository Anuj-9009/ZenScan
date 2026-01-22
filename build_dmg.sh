#!/bin/bash

# ============================================
# ZenScan Build & DMG Creation Script
# ============================================
# This script builds the ZenScan app and creates
# a distributable DMG file.
#
# Requirements:
# - Xcode 15+ installed
# - Run: sudo xcode-select -s /Applications/Xcode.app
# ============================================

set -e

# Configuration
PROJECT_NAME="ZenScan"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_NAME="${PROJECT_NAME}.app"
DMG_NAME="${PROJECT_NAME}.dmg"
VOLUME_NAME="${PROJECT_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║       ZenScan Build Script             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Check for Xcode
if ! xcodebuild -version &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed or not properly configured.${NC}"
    echo -e "${YELLOW}Please install Xcode from the App Store and run:${NC}"
    echo -e "  sudo xcode-select -s /Applications/Xcode.app"
    exit 1
fi

echo -e "${GREEN}✓ Xcode found${NC}"
xcodebuild -version

# Clean previous builds
echo ""
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build the app
echo ""
echo -e "${YELLOW}Building ${PROJECT_NAME} (Release)...${NC}"
xcodebuild \
    -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
    -scheme "${PROJECT_NAME}" \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    -archivePath "${BUILD_DIR}/${PROJECT_NAME}.xcarchive" \
    archive \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

# Export the app
echo ""
echo -e "${YELLOW}Exporting app...${NC}"

# Create export options plist
cat > "${BUILD_DIR}/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
EOF

# Copy app from archive
APP_PATH="${BUILD_DIR}/${PROJECT_NAME}.xcarchive/Products/Applications/${APP_NAME}"
if [ ! -d "${APP_PATH}" ]; then
    # Fallback: look in DerivedData
    APP_PATH=$(find "${BUILD_DIR}/DerivedData" -name "${APP_NAME}" -type d | head -1)
fi

if [ ! -d "${APP_PATH}" ]; then
    echo -e "${RED}Error: Could not find built app${NC}"
    exit 1
fi

echo -e "${GREEN}✓ App found at: ${APP_PATH}${NC}"

# Create DMG staging directory
DMG_STAGING="${BUILD_DIR}/dmg_staging"
rm -rf "${DMG_STAGING}"
mkdir -p "${DMG_STAGING}"

# Copy app to staging
cp -R "${APP_PATH}" "${DMG_STAGING}/"

# Create Applications symlink
ln -s /Applications "${DMG_STAGING}/Applications"

# Create the DMG
echo ""
echo -e "${YELLOW}Creating DMG...${NC}"

DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
rm -f "${DMG_PATH}"

hdiutil create \
    -volname "${VOLUME_NAME}" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

# Copy to Downloads
DOWNLOADS_PATH="${HOME}/Downloads/${DMG_NAME}"
cp "${DMG_PATH}" "${DOWNLOADS_PATH}"

# Cleanup
rm -rf "${DMG_STAGING}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Build Complete!             ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "DMG created at:"
echo -e "  ${GREEN}${DOWNLOADS_PATH}${NC}"
echo ""
echo -e "To install: Open the DMG and drag ZenScan to Applications"
