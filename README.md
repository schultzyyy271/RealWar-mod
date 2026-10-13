# GemDebugDemo (Theos)

Theos tweak/dylib port of the SwiftUI GemDebugDemo mock.

- `GemState` holds a local gem count (starts at 0).
- `GemOverlay` is a UIKit port of `ContentView`, shown as a draggable card.
- Debug button (`set_gemsAmountBigIntegerObservedValue`) is compiled in by default
  and removed with `make package FINALPACKAGE=1`, mirroring the original `#if DEBUG`.
- No hooks into other classes; state is entirely self-contained.

## Setup
1. Edit `GemDebugDemo.plist` -> put the bundle ID of **your own app** in `Bundles`.
2. Edit `INSTALL_TARGET_PROCESSES` in `Makefile` to that app's executable name.
3. `export THEOS=~/theos` then `make package` (or `make package install` with `THEOS_DEVICE_IP` set).

Output: `.theos/obj/debug/GemDebugDemo.dylib` (and a .deb in `packages/`).
To embed it in your own app instead of using substrate, copy the dylib into the app
bundle and add a load command with your signing tool of choice.
