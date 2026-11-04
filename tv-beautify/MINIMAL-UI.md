# Minimal beautiful TV (Apple TV style)

Your Instagram reel is basically: **few apps in a dock + big artwork + no clutter**.  
**FLauncher** defaults to showing **every** TV app and **every** sideloaded “mobile” app — that’s why it feels busy.

## Recommended: Vibe Launcher

- [Vibe Launcher](https://github.com/maydings/vibe-launcher) — ~1.7 MB, built for **1–2 GB RAM**
- Dock (up to ~6 favorites), full-screen app backdrops, no ad rows
- **Default launcher** toggle **inside the app** (works better on **Wisdom Share** than disabling stock)

```bash
cd ~/tv-beautify
curl -fsSL -o minimal-apple-tv.sh \
  "https://raw.githubusercontent.com/hafizumair74/cart/cursor/tv-beautify-launcher-8673/tv-beautify/minimal-apple-tv.sh"
chmod +x minimal-apple-tv.sh
./minimal-apple-tv.sh 192.168.0.103
```

### On the TV after install

| Step | Action |
|------|--------|
| 1 | Vibe **Settings** → **Default launcher** → **Vibe Launcher** |
| 2 | Edit **dock** → only apps you actually use |
| 3 | Press **Home** → should stay on Vibe, not Wisdom Share grid |
| 4 | Optional **Debloat** in Vibe settings (never disable `com.cvte.tv.launcher.space`) |

## Alternative: Projectivy (one row only)

If you prefer Projectivy:

1. Run `./wisdom-share-fix.sh 192.168.0.103`
2. Projectivy **Settings → Edit categories** → turn **Visible OFF** on all rows except one
3. **Manage apps** → hide everything except 3–6 favorites
4. **Appearance** → hide row titles, dark wallpaper from `/sdcard/Download/DevTV/`

## What to avoid on 1GB Wisdom Share TV

- Two full rows of “TV Apps” + “Mobile Apps” (current FLauncher look)
- Video boot / live wallpaper on Projectivy (slow)
- Disabling **com.cvte.tv.launcher.space**
