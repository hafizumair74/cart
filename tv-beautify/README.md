# TV beautify (Chinese / generic Android smart TV)

This folder installs a **fast, ad‑friendly home screen** on your TV from your **laptop** (same Wi‑Fi):

| App | Purpose |
|-----|---------|
| [Projectivy Launcher](https://github.com/spocky/miproja1) | Custom home UI — hide apps, wallpapers, clean grid |
| [Aerial Views](https://github.com/theothernt/AerialViews) | Beautiful aerial video screensaver |

**Important:** A cloud agent cannot reach your home network. You run **one script on the laptop** that is already on the same Wi‑Fi as the TV.

## One-time setup on the TV (~2 minutes)

### If you only see **System Info** (like `SMART_TV`, Android 12, 1GB RAM)

Your TV **is** Android 12 — good. Developer mode is just hidden:

1. Open **Settings → About → System Info** (the screen you photographed).
2. Highlight **Firmware Version** (`20240109_…`) and press **OK on the remote 7 times quickly**.  
   If nothing happens, try the same on **Android Version** (the row that says `12`).
3. You should see **“You are now a developer”** (or similar). Go **Back** to the main **Settings** list.
4. Open the new **Developer options** menu (often at the bottom of Settings, or under **System**).
5. Turn **USB debugging** **ON**. If you see **Network debugging** / **Wireless debugging**, turn that **ON** too.
6. Find the TV **IP address**: **Settings → Network** (or **Wi‑Fi**) → your connected network → **IP** (e.g. `192.168.0.105`).  
   *(IP is not on the System Info page — use Network/Wi‑Fi.)*

**1GB RAM tip:** use the lightweight launcher mode on the laptop:

```bash
LOW_RAM=1 ./beautify-tv.sh YOUR_TV_IP
```

This installs **FLauncher** instead of Projectivy and skips the heavy video screensaver so the UI stays smooth.

### Standard Android TV path

1. **Settings → About** → tap **Build** **7 times** → Developer mode on.
2. **Settings → Developer options** → **USB debugging** ON (+ network debugging if shown).
3. **Settings → Network → Wi‑Fi** → note **IP address**.

If the TV asks to **allow debugging** from your laptop, choose **Allow** (and “Always allow” if offered).

## Run on your laptop

### Linux / macOS

```bash
cd tv-beautify
chmod +x beautify-tv.sh
./beautify-tv.sh YOUR_TV_IP
```

Example:

```bash
./beautify-tv.sh 192.168.0.105
```

### Windows (Git Bash or WSL)

Use the same commands inside Git Bash, or install [platform-tools](https://developer.android.com/tools/releases/platform-tools) and run the script from WSL.

## If connection fails

- Laptop and TV must be on the **same Wi‑Fi** (not guest network).
- Try another port: `ADB_PORT=5556 ./beautify-tv.sh YOUR_TV_IP`
- Some TVs need a **USB cable once** to enable wireless ADB (then unplug).
- If **ADB never connects**, the TV may **not be Android** — this method only works on Android TV / Google TV / Fire TV–class systems.

## Revert

Backup files are saved under `tv-beautify/.backup/`. To re-enable the old launcher:

```bash
adb connect YOUR_TV_IP:5555
adb shell pm enable PACKAGE_NAME_FROM_BACKUP
adb shell cmd package set-home-activity PREVIOUS_HOME_COMPONENT
```

## What the script does

1. Downloads official APKs (with checksum for Projectivy).
2. Installs Projectivy + Aerial Views over ADB.
3. Sets Projectivy as the default **Home** app.
4. Disables the previous launcher package when safe (optional: `--no-disable-old-launcher`).
5. Enables Aerial Views as the system screensaver.
