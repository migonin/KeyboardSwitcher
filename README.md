# KeyboardSwitcher

Share one Bluetooth keyboard and trackpad between two Macs that take turns on the same monitor.

Plug a laptop into the monitor, and the keyboard and trackpad switch to it. Unplug it, and they're free for the other Mac. This works well with an Apple Studio Display and a Magic Keyboard and Magic Trackpad, but any external display and Bluetooth keyboard, mouse or trackpad should work.

## How it works

KeyboardSwitcher is a small menu bar app that runs on **both** Macs:

- **Display connected:** it pairs and connects your chosen devices. If the other Mac still has them, it retries every 5 seconds until they're free.
- **Display disconnected:** it unpairs the devices, so the other Mac can take them.
- **Waking from sleep:** it checks the display again, in case the Mac was unplugged while asleep.

A Magic Keyboard or Trackpad can be paired with only one Mac at a time, so the app moves the pairing from one Mac to the other.

## Requirements

- Two Macs running macOS 13 or later, each with KeyboardSwitcher installed.
- Only one Mac connected to the display at a time. The Studio Display has a single computer input, so this is automatic.

## Install

Build from source. You need the Xcode command line tools (`xcode-select --install`):

```sh
git clone https://github.com/migonin/KeyboardSwitcher.git
cd KeyboardSwitcher
./build.sh --install
open /Applications/KeyboardSwitcher.app
```

The app is signed locally, not notarized by Apple. If you download a prebuilt `KeyboardSwitcher.app` instead of building it, macOS will block it the first time you open it. Open it anyway from **System Settings → Privacy & Security → Open Anyway**.

## Set up

Do this on each Mac:

1. Make sure the keyboard and trackpad are paired with this Mac. On the second Mac, pair them once in System Settings → Bluetooth.
2. Open KeyboardSwitcher and allow Bluetooth access when macOS asks.
3. In the keyboard icon in the menu bar:
   - **Devices:** tick your keyboard and trackpad.
   - **Display:** pick your monitor, or leave it on **Any External Display**.
   - **Launch at Login:** turn it on.

Then unplug one Mac and plug in the other. The devices should follow in a few seconds.

## Troubleshooting

- **Devices don't switch:** the Mac you unplugged must be awake to release them. If it's asleep, the switch happens when it wakes. To force it, turn the keyboard and trackpad off and on.
- **What happened:** the app logs to `~/Library/Logs/KeyboardSwitcher.log`.
- **Current state from the terminal:** run `/Applications/KeyboardSwitcher.app/Contents/MacOS/KeyboardSwitcher status`.
- **Bluetooth permission keeps coming back:** this can happen after a rebuild, because each build has a new signature. Allow it again.

## Limitations

- macOS has no public API for unpairing a Bluetooth device. KeyboardSwitcher uses the same private call that System Settings uses, so a future macOS update could break it.
- "Any External Display" also reacts to projectors and other monitors. Pick a specific display if you plug into other screens.

## License

MIT
