# KeyboardSwitcher

Menu bar app that hands a Magic Keyboard and Magic Trackpad to whichever Mac is plugged into the Studio Display.

Run it on **both** Macs:

- When the Studio Display connects, it pairs and connects the devices. If the other Mac still holds them, it retries every 5 seconds.
- When the display disconnects, it unpairs the devices. It also checks after waking from sleep, in case the Mac was unplugged while asleep.

## Install

```sh
./build.sh --install
open /Applications/KeyboardSwitcher.app
```

Allow Bluetooth access when asked. Then turn on **Launch at Login** in the menu bar item.

Check the current state without changing anything:

```sh
/Applications/KeyboardSwitcher.app/Contents/MacOS/KeyboardSwitcher status
```

## Settings

```sh
defaults write com.igonin.KeyboardSwitcher deviceAddresses -array "38:09:FB:1B:6D:2A" "3C:7D:0A:5C:A4:77"
defaults write com.igonin.KeyboardSwitcher displayName "Studio Display"
```

Get the device addresses from `system_profiler SPBluetoothDataType`.

## If a device does not switch

The Mac that releases a device must be awake. If the device still doesn't show up on the new Mac, turn the device off and on again: that puts it into pairing mode, and the next retry picks it up.
