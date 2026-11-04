# Developer TV look (Projectivy on 1GB SMART_TV)

After **fix-tv-home.sh**, Home works and Projectivy is default. Polish the look on the **remote** (about 5 minutes).

## 1. Fix Home if it breaks again

```bash
./fix-tv-home.sh 192.168.0.103
```

Never disable the stock launcher on this board — use Projectivy **Accessibility** instead.

## 2. Projectivy — developer preset

Open **Projectivy → Settings (gear)**:

| Area | Recommendation |
|------|----------------|
| **Wallpaper** | Local file → `/sdcard/Download/DevTV/wall-code-dark.jpg` |
| **Wallpaper mode** | Static only (no video — saves RAM) |
| **Card background** | Dark, ~70% opacity |
| **Card size** | Medium or small |
| **Focus effect** | Subtle glow or border (not huge zoom) |
| **Status bar** | Minimal icons |
| **Categories** | Create: **Code · Media · Tools · System** |
| **Apps** | Hide: App Store promos, duplicate players, anything you never open |
| **Override / Accessibility** | **ON** if Home still flashes the old UI briefly |

## 3. Apps worth keeping visible

- YouTube, VLC, AirScreen (from your TV)
- **Send Files to TV** or **Material Files** (sideload) for APK/wallpapers
- Optional: **Termux** (if you sideload — terminal on TV)

## 4. Re-push wallpapers

```bash
./developer-tv.sh 192.168.0.103
```

(Disabling stock launcher is now **off** by default.)

## 5. Optional dark vibe

- HDMI black bars: Projectivy wallpaper “fit + blurred background”
- Screensaver: leave **off** on 1GB RAM, or static images only
