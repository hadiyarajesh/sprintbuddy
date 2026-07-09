#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------------------------------------------
# Build the nearby macOS app into a .dmg.
#
# Project discovery: looks for a single *.xcodeproj starting from this script's
# parent directory and from the current working directory, walking up to 2
# parent directories from each. The first match wins — so the script is not
# tied to any one project name.
#
# Signing: uses "Apple Development" (a local dev build, not notarized). Adjust
# or remove the CODE_SIGN_IDENTITY line below if you want different signing.
# ----------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check a directory and up to 2 of its parents for a *.xcodeproj.
find_xcodeproj() {
  local dir
  dir="$(cd "$1" 2>/dev/null && pwd)" || return 1
  local level match
  for level in 0 1 2; do
    match="$(find "$dir" -maxdepth 1 -name '*.xcodeproj' 2>/dev/null | head -1)"
    if [ -n "$match" ]; then
      printf '%s\n' "$match"
      return 0
    fi
    dir="$(cd "$dir/.." && pwd)"
  done
  return 1
}

PROJECT_FILE=""
for start in "$SCRIPT_DIR/.." "$PWD"; do
  if PROJECT_FILE="$(find_xcodeproj "$start")" && [ -n "$PROJECT_FILE" ]; then
    break
  fi
  PROJECT_FILE=""
done

if [ -z "$PROJECT_FILE" ]; then
  echo "error: no .xcodeproj found near $SCRIPT_DIR or $PWD (searched up to 2 parents)" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$PROJECT_FILE")" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_FILE" .xcodeproj)"

# Pick a scheme: prefer one matching the project name, else the first listed.
SCHEMES="$(xcodebuild -project "$PROJECT_FILE" -list 2>/dev/null | awk '/Schemes:/{f=1; next} f && NF {print $1}')"
if printf '%s\n' "$SCHEMES" | grep -qx "$PROJECT_NAME"; then
  SCHEME="$PROJECT_NAME"
else
  SCHEME="$(printf '%s\n' "$SCHEMES" | head -1)"
fi
if [ -z "${SCHEME:-}" ]; then
  echo "error: no scheme found in $PROJECT_FILE" >&2
  exit 1
fi

BUILD_DIR="$PROJECT_DIR/build"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
DMG_STAGING_DIR="$BUILD_DIR/dmg"
RELEASE_DIR="$DERIVED_DATA_DIR/Build/Products/Release"

echo "Project: $PROJECT_FILE"
echo "Scheme:  $SCHEME"

cd "$PROJECT_DIR"

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGN_IDENTITY="Apple Development" \
  build

# Locate the built .app (its product name may differ from the scheme).
APP_PATH="$(find "$RELEASE_DIR" -maxdepth 1 -name '*.app' 2>/dev/null | head -1)"
if [ -z "$APP_PATH" ]; then
  echo "error: no .app produced in $RELEASE_DIR" >&2
  exit 1
fi
APP_NAME="$(basename "$APP_PATH" .app)"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

rm -rf "$DMG_STAGING_DIR" "$DMG_PATH"
mkdir -p "$DMG_STAGING_DIR"

cp -R "$APP_PATH" "$DMG_STAGING_DIR/"
ln -s /Applications "$DMG_STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$DMG_STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created $DMG_PATH"
