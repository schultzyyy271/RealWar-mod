# RealWarMod (Theos)

Theos tweak that modifies gems in RealWar by hooking into the IL2CPP runtime.

## Architecture

- `IL2CPPBridge` – Interfaces with the Unity IL2CPP runtime to read/write the actual game state:
  - Finds `PersistentDataManager.Instance` via IL2CPP reflection APIs
  - Accesses `persistentData.gemsAmountBigIntegerObservedValue`
  - Calls `BigIntegerObservedValue.Add()` at RVA `0x27986A4` to modify gems
- `GemState` – Wrapper that uses `IL2CPPBridge` when available, falls back to local `NSUserDefaults` storage
- `GemOverlay` – Draggable UIKit card showing current gems with Set/Add buttons
  - 🟢 Live indicator when connected to actual game state
  - 🟡 Offline indicator when using local fallback

## Key RVAs (from dump.cs)

| Symbol | RVA |
|--------|-----|
| `PersistentDataManager.Instance` | static field offset 0x0 |
| `PersistentData.gemsAmountBigIntegerObservedValue` | instance offset 0x28 |
| `BigIntegerObservedValue.Add(BigInteger, bool)` | 0x27986A4 |
| `ObservedValue<BigInteger>.SetValue` | 0x3EBB86C |

## Setup

1. Ensure `THEOS` points to your Theos installation
2. Target bundle ID: `com.devdop.realwar` (in `RealWarMod.plist`)
3. Build: `make package` or `make package install` with `THEOS_DEVICE_IP` set

## Output

- `.theos/obj/debug/RealWarMod.dylib`
- Debian package in `packages/`

## Notes

- IL2CPP initialization is delayed 0.5s after app becomes active to ensure runtime is ready
- If IL2CPP bridge fails (game update changes offsets), falls back to harmless local-only mode
- Check device logs (`Console.app` or `idevicesyslog`) for `[RealWarMod]` messages to debug
