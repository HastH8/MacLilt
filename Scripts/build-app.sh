#!/bin/zsh
set -euo pipefail

SCRIPT_DIRECTORY=${0:A:h}
PROJECT_DIRECTORY=${SCRIPT_DIRECTORY:h}
CONFIGURATION=${1:-release}
APP_DIRECTORY="$PROJECT_DIRECTORY/artifacts/MacEase.app"
CONTENTS_DIRECTORY="$APP_DIRECTORY/Contents"
BIN_DIRECTORY=$(cd "$PROJECT_DIRECTORY" && swift build -c "$CONFIGURATION" --show-bin-path)

cd "$PROJECT_DIRECTORY"
swift build -c "$CONFIGURATION"
mkdir -p "$CONTENTS_DIRECTORY/MacOS" "$CONTENTS_DIRECTORY/Resources"
cp "$BIN_DIRECTORY/MacEase" "$CONTENTS_DIRECTORY/MacOS/MacEase"
cp "$PROJECT_DIRECTORY/Packaging/Info.plist" "$CONTENTS_DIRECTORY/Info.plist"
cp "$PROJECT_DIRECTORY/Packaging/Resources/AppIcon.icns" "$CONTENTS_DIRECTORY/Resources/AppIcon.icns"
cp "$PROJECT_DIRECTORY/Packaging/Resources/BrandIcon.png" "$CONTENTS_DIRECTORY/Resources/BrandIcon.png"
if [[ -d "$APP_DIRECTORY/MacEase_MacEase.bundle" ]]; then
    STALE_DIRECTORY=$(mktemp -d)
    mv "$APP_DIRECTORY/MacEase_MacEase.bundle" "$STALE_DIRECTORY/"
fi
chmod 755 "$CONTENTS_DIRECTORY/MacOS/MacEase"

# Ad-hoc signing is for local development only. Release signing is documented separately.
codesign --force --sign - "$APP_DIRECTORY"
codesign --verify --deep --strict "$APP_DIRECTORY"

print "Built $APP_DIRECTORY"
