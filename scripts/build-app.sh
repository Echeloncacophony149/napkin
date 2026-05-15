#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Napkin"
BUILD_DIR=".build/release"
APP_DIR=".build/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
LOGO_SOURCE="logo.png"
ICON_NAME="AppIcon"
ICON_FILE="${ICON_NAME}.icns"
ICONSET_DIR=".build/${ICON_NAME}.iconset"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

swift build -c release

rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"
cp "${BUILD_DIR}/${APP_NAME}" "${MACOS_DIR}/${APP_NAME}"

if [[ ! -f "${LOGO_SOURCE}" ]]; then
  echo "Missing ${LOGO_SOURCE}; cannot build app icon." >&2
  exit 1
fi

rm -rf "${ICONSET_DIR}"
mkdir -p "${ICONSET_DIR}"

make_icon() {
  local points="$1"
  local scale="$2"
  local pixels=$((points * scale))
  local suffix=""

  if [[ "${scale}" -eq 2 ]]; then
    suffix="@2x"
  fi

  sips -Z "${pixels}" "${LOGO_SOURCE}" \
    --padToHeightWidth "${pixels}" "${pixels}" \
    --out "${ICONSET_DIR}/icon_${points}x${points}${suffix}.png" >/dev/null
}

make_icon 16 1
make_icon 16 2
make_icon 32 1
make_icon 32 2
make_icon 128 1
make_icon 128 2
make_icon 256 1
make_icon 256 2
make_icon 512 1
make_icon 512 2

iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/${ICON_FILE}"

cat > "${CONTENTS_DIR}/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>local.napkin.whiteboard</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIconFile</key>
  <string>${ICON_FILE}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.1</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright (c) 2026 Alexander Kharchenko</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

xattr -cr "${APP_DIR}"
codesign_args=(--force --deep --sign "${CODESIGN_IDENTITY}")

if [[ "${CODESIGN_IDENTITY}" != "-" ]]; then
  codesign_args+=(--timestamp --options runtime)
fi

codesign "${codesign_args[@]}" "${APP_DIR}"
codesign --verify --deep --strict --verbose=2 "${APP_DIR}"

echo "Built ${APP_DIR}"
