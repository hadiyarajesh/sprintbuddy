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
# Signing: prefers "Developer ID Application" when present in the keychain
# (proper direct distribution), falling back to "Apple Development" (runs
# locally, but downloads need the quarantine flag cleared). The app is NOT
# sandboxed and uses no App Groups, so Xcode embeds no provisioning profile —
# nothing expires (a sandboxed/app-group build would embed a 7-day development
# profile, after which macOS refuses to launch the app with launchd error 163).
# Team signing (either identity) keeps SMAppService login items working, which
# ad-hoc signing does not.
#
# Notarization: if an App Store Connect API key is available, the DMG is
# submitted to Apple and stapled, so downloads open with no Gatekeeper
# friction. Credentials are discovered as:
#   key    NOTARY_KEY env var, or a *AuthKey_<KEYID>.p8 in ~/.appstoreconnect
#          or next to the project
#   key id NOTARY_KEY_ID env var, or parsed from the key filename
#   issuer NOTARY_ISSUER env var, or a .notary-issuer file next to the project
# Without credentials the DMG is still built (just not notarized).
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

# Prefer Developer ID when the keychain has one. A manually specified identity
# conflicts with Xcode's automatic signing, so switch the style to Manual for
# Developer ID builds (fine here: no capability needs a provisioning profile).
SIGN_ARGS=()
if security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
  SIGN_IDENTITY="Developer ID Application"
  # INJECT_BASE_ENTITLEMENTS=NO drops the get-task-allow (debugger) entitlement
  # Xcode adds by default — notarization rejects binaries that carry it.
  SIGN_ARGS=(CODE_SIGN_STYLE=Manual CODE_SIGN_IDENTITY="$SIGN_IDENTITY" OTHER_CODE_SIGN_FLAGS="--timestamp" CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO)
else
  SIGN_IDENTITY="Apple Development"
  echo "note: no Developer ID Application identity found — dev-signing instead" >&2
  SIGN_ARGS=(CODE_SIGN_IDENTITY="$SIGN_IDENTITY")
fi
echo "Signing: $SIGN_IDENTITY"

xcodebuild \
  -project "$PROJECT_FILE" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  "${SIGN_ARGS[@]}" \
  build

# Locate the built .app (its product name may differ from the scheme).
APP_PATH="$(find "$RELEASE_DIR" -maxdepth 1 -name '*.app' 2>/dev/null | head -1)"
if [ -z "$APP_PATH" ]; then
  echo "error: no .app produced in $RELEASE_DIR" >&2
  exit 1
fi
APP_NAME="$(basename "$APP_PATH" .app)"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"

# Fail loudly if a provisioning profile snuck back in (it would expire in ~7
# days and brick the app) or the signature is broken.
if [ -e "$APP_PATH/Contents/embedded.provisionprofile" ]; then
  echo "error: build embedded a provisioning profile — a capability requiring" >&2
  echo "provisioning (sandbox/app groups/...) was probably re-enabled." >&2
  exit 1
fi
codesign --verify --deep --strict "$APP_PATH"

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

# --- Notarize + staple (skipped when credentials are unavailable) -----------
NOTARY_KEY="${NOTARY_KEY:-$(find "$HOME/.appstoreconnect" "$PROJECT_DIR" -maxdepth 1 -name '*AuthKey_*.p8' 2>/dev/null | head -1)}"
if [ -z "${NOTARY_KEY_ID:-}" ] && [ -n "$NOTARY_KEY" ]; then
  # AuthKey_<KEYID>.p8 (possibly with a human-readable prefix)
  NOTARY_KEY_ID="$(basename "$NOTARY_KEY" .p8 | sed 's/.*AuthKey_//')"
fi
if [ -z "${NOTARY_ISSUER:-}" ] && [ -f "$PROJECT_DIR/.notary-issuer" ]; then
  NOTARY_ISSUER="$(tr -d '[:space:]' < "$PROJECT_DIR/.notary-issuer")"
fi

if [ "$SIGN_IDENTITY" = "Developer ID Application" ] \
   && [ -n "$NOTARY_KEY" ] && [ -n "${NOTARY_KEY_ID:-}" ] && [ -n "${NOTARY_ISSUER:-}" ]; then
  # Sign the DMG itself too, so Gatekeeper sees a signature on the container
  # as well as the app inside.
  codesign --force --sign "Developer ID Application" --timestamp "$DMG_PATH"
  echo "Notarizing (key id $NOTARY_KEY_ID)…"
  SUBMIT_OUT="$(xcrun notarytool submit "$DMG_PATH" \
    --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" \
    --wait 2>&1)" || { printf '%s\n' "$SUBMIT_OUT" >&2; exit 1; }
  printf '%s\n' "$SUBMIT_OUT" | grep -E "id:|status:" | head -4
  if ! printf '%s\n' "$SUBMIT_OUT" | grep -q "status: Accepted"; then
    SUBMISSION_ID="$(printf '%s\n' "$SUBMIT_OUT" | awk '/^ *id:/{print $2; exit}')"
    echo "error: notarization was not accepted — details:" >&2
    xcrun notarytool log "$SUBMISSION_ID" \
      --key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER" >&2 || true
    exit 1
  fi
  xcrun stapler staple "$DMG_PATH"
  echo "Notarized and stapled: $DMG_PATH"
else
  echo "note: skipping notarization (need Developer ID signing + NOTARY_KEY/NOTARY_KEY_ID/NOTARY_ISSUER)" >&2
fi
