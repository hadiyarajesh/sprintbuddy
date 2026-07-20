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
# Signing: ad-hoc ("-"), with no provisioning profile. A "Apple Development"
# signature embeds a development provisioning profile that expires in ~7 days,
# after which macOS refuses to launch the app ("can't be opened", launchd error
# 163). Ad-hoc signing has no profile and never expires; the App Sandbox +
# App Group entitlements are still honored locally. Downloads still need the
# quarantine flag cleared (xattr -dr com.apple.quarantine) since it isn't
# notarized. Switch to a Developer ID identity + notarization for friction-free
# distribution.
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

# Build unsigned: xcodebuild refuses to sign a sandboxed / App-Group app
# without a provisioning profile, so skip signing here and re-sign ad-hoc
# below (which needs no profile and never expires).
xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  build

# Locate the built .app (its product name may differ from the scheme).
APP_PATH="$(find "$RELEASE_DIR" -maxdepth 1 -name '*.app' 2>/dev/null | head -1)"
if [ -z "$APP_PATH" ]; then
  echo "error: no .app produced in $RELEASE_DIR" >&2
  exit 1
fi
APP_NAME="$(basename "$APP_PATH" .app)"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# --- Ad-hoc re-sign (inside-out) -------------------------------------------
# Map each product bundle name -> its entitlements file, read from the
# project's build settings so this stays project-agnostic.
echo "Signing ad-hoc…"
ENT_MAP="$(mktemp)"
xcodebuild -project "$PROJECT_FILE" -scheme "$SCHEME" -configuration Release \
  -showBuildSettings -json 2>/dev/null | python3 -c '
import json, sys, os
for t in json.load(sys.stdin):
    bs = t.get("buildSettings", {})
    name = bs.get("FULL_PRODUCT_NAME", "")
    ent = bs.get("CODE_SIGN_ENTITLEMENTS", "")
    if name and ent:
        base = bs.get("PROJECT_DIR", "") or bs.get("SRCROOT", "")
        path = ent if os.path.isabs(ent) else os.path.join(base, ent)
        print(f"{name}\t{path}")
' > "$ENT_MAP"

entitlements_for() {  # basename of bundle -> entitlements path (may be empty)
  awk -F'\t' -v n="$1" '$1==n {print $2; exit}' "$ENT_MAP"
}

sign_bundle() {
  local bundle="$1" ent
  ent="$(entitlements_for "$(basename "$bundle")")"
  if [ -n "$ent" ] && [ -f "$ent" ]; then
    codesign --force --sign - --entitlements "$ent" "$bundle"
  else
    codesign --force --sign - "$bundle"
  fi
}

# 1) Frameworks and dylibs first, no entitlements. (They don't nest inside
#    each other here, so relative order among them doesn't matter — they just
#    all need to be signed before the app bundles that embed them.)
while IFS= read -r -d '' f; do
  codesign --force --sign - "$f"
done < <(find "$APP_PATH" \( -name '*.framework' -o -name '*.dylib' \) -print0)

# 2) Nested apps (e.g. embedded login-item helpers), each with its entitlements.
while IFS= read -r -d '' nested; do
  sign_bundle "$nested"
done < <(find "$APP_PATH" -mindepth 1 -name '*.app' -print0)

# 3) Finally the outer app, with its entitlements.
sign_bundle "$APP_PATH"
rm -f "$ENT_MAP"

# Verify before packaging so a bad signature fails the build loudly.
codesign --verify --deep --strict "$APP_PATH"
echo "Signature: $(codesign -dvv "$APP_PATH" 2>&1 | grep -E 'Signature|flags' | head -1)"

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
