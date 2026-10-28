#!/bin/zsh
# Builds KeyboardSwitcher.app.
#   --install  copies it into /Applications
#   --zip      packs it into build/KeyboardSwitcher.zip for a GitHub release
set -euo pipefail
cd "$(dirname "$0")"

flags=(-c release --arch arm64 --arch x86_64)
swift build $flags
app=build/KeyboardSwitcher.app
rm -rf "$app"
mkdir -p "$app/Contents/MacOS"
cp "$(swift build $flags --show-bin-path)/KeyboardSwitcher" "$app/Contents/MacOS/"
cp Resources/Info.plist "$app/Contents/"
codesign --force --sign - "$app"
echo "Built $app"

if [[ "${1:-}" == "--zip" ]]; then
    ditto -c -k --keepParent "$app" build/KeyboardSwitcher.zip
    echo "Packed build/KeyboardSwitcher.zip"
fi

if [[ "${1:-}" == "--install" ]]; then
    pkill -x KeyboardSwitcher || true
    rm -rf /Applications/KeyboardSwitcher.app
    cp -R "$app" /Applications/
    echo "Installed /Applications/KeyboardSwitcher.app"
fi
