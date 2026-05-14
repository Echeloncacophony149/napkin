#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Napkin"
APP_DIR=".build/${APP_NAME}.app"
DMG_STAGING_DIR=".build/dmg"
DMG_PATH=".build/${APP_NAME}.dmg"

scripts/build-app.sh

rm -rf "${DMG_STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${DMG_STAGING_DIR}"

cp -R "${APP_DIR}" "${DMG_STAGING_DIR}/${APP_NAME}.app"
ln -s /Applications "${DMG_STAGING_DIR}/Applications"

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${DMG_STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}"

echo "Built ${DMG_PATH}"
