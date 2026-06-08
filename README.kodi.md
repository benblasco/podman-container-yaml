# Kodi configuration changes for better performance when on Wifi

As proposed by Cursor.ai due to playback issues 20260608

## Kodi playback cache

**File:** `/storage/.kodi/userdata/guisettings.xml`

| Setting | Before | After |
|---------|--------|-------|
| `filecache.buffermode` | 4 (network filesystems) | **1** (cache all remote files) |
| `filecache.memorysize` | 20 MB | **100 MB** |
| `filecache.readfactor` | 400 (4.00×) | 400 (unchanged) |

These are the settings Kodi 21 actually uses (Settings → Services → Caching).

**Backup:** `/storage/.kodi/userdata/guisettings.xml.bak.20260608`

---

## Kodi advanced settings (inactive)

**File:** `/storage/.kodi/userdata/advancedsettings.xml`

Contains cache settings (`buffermode=1`, `memorysize=104857600`, `readfactor=400`). **Kodi 21 ignores cache settings in this file** — kept in place but has no effect.

---

## WiFi tuning (boot script)

**File:** `/storage/.config/autostart.sh` (runs on every boot)

1. Waits 10 seconds after boot
2. Disables WiFi power save: `iw dev wlan0 set power_save off`
3. If still on 2.4 GHz (`freq` < 5000 MHz), disconnects and reconnects `eraser215` via ConnMan, then disables power save again

---
