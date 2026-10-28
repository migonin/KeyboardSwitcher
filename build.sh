#!/bin/zsh
# Builds KeyboardSwitcher.app. Pass --install to copy it into /Applications.
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

if [[ "${1:-}" == "--install" ]]; then
    pkill -x KeyboardSwitcher || true
    rm -rf /Applications/KeyboardSwitcher.app
    cp -R "$app" /Applications/
    echo "Installed /Applications/KeyboardSwitcher.app"
fi
