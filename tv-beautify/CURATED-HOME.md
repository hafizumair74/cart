# Your own curated home (beautiful + light)

You keep **only** what was on your Wisdom screen — without the big WISDOM banner, weather clutter, or extra rows.

## One command (laptop)

```bash
cd ~/tv-beautify
curl -fsSL -o beautiful-curated-home.sh \
  "https://raw.githubusercontent.com/hafizumair74/cart/cursor/tv-beautify-launcher-8673/tv-beautify/beautiful-curated-home.sh"
chmod +x beautiful-curated-home.sh
./beautiful-curated-home.sh 192.168.0.103
```

This installs **Couchy Launcher** (glass, one screen, local wallpapers), **8 dark/cinematic wallpapers**, **Material Files** for Media, removes **FLauncher / Projectivy / Vibe / Arc**, and sets Couchy as Home.

## Your app list (dock only)

| Tile | Use in Couchy |
|------|----------------|
| YouTube, Netflix, Prime, Disney+, VLC | Streaming |
| AirScreen | Cast from laptop |
| Browser | Web |
| Material Files | Replaces **Media Center** |
| App Store, Tamasha, Dunya, VPN, Kindlink | Only if you still use them |

Hide **TV Assistant** and anything else via long-press → Hide.

## Wallpapers

On TV: `/sdcard/Download/DevTV/walls/` — pick **01–08** in Couchy → Wallpaper → Photo.

Static images only (smooth on **1GB RAM**).

## If Home shows old Wisdom UI again

```bash
./wisdom-share-fix.sh 192.168.0.103
```

(Uses Projectivy accessibility trick; or set default launcher inside Couchy settings.)

## Boot WISDOM video

Still separate — hidden menu **1147** or root. Custom home does not change power-on logo.

## Try Vibe instead of Couchy

```bash
INSTALL=vibe REMOVE_OLD=1 KEEP=vibe ./launcher-manage.sh 192.168.0.103
```

Then dock only your apps + wallpaper from `DevTV/walls/`.
