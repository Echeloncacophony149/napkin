#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Napkin"
APP_DIR=".build/${APP_NAME}.app"
DMG_STAGING_DIR=".build/dmg"
DMG_PATH=".build/${APP_NAME}.dmg"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD:-}"

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

if [[ "${CODESIGN_IDENTITY}" != "-" ]]; then
  codesign --force --sign "${CODESIGN_IDENTITY}" --timestamp "${DMG_PATH}"

  if [[ -n "${NOTARYTOOL_PROFILE}" ]]; then
    xcrun notarytool submit "${DMG_PATH}" \
      --keychain-profile "${NOTARYTOOL_PROFILE}" \
      --wait
    xcrun stapler staple "${DMG_PATH}"
    xcrun stapler validate "${DMG_PATH}"
  elif [[ -n "${APPLE_ID}" && -n "${APPLE_TEAM_ID}" && -n "${APPLE_APP_PASSWORD}" ]]; then
    xcrun notarytool submit "${DMG_PATH}" \
      --apple-id "${APPLE_ID}" \
      --team-id "${APPLE_TEAM_ID}" \
      --password "${APPLE_APP_PASSWORD}" \
      --wait
    xcrun stapler staple "${DMG_PATH}"
    xcrun stapler validate "${DMG_PATH}"
  else
    echo "Built a signed DMG, but skipped notarization because no notarytool credentials were provided." >&2
  fi
else
  echo "Built an ad-hoc signed DMG for local testing. Set CODESIGN_IDENTITY for a distributable release." >&2
fi

echo "Built ${DMG_PATH}"
