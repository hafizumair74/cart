# DevDock — your own TV launcher

**DevDock** is a custom Android TV home screen built for your TV:

- Large glass-style app tiles on a **random wallpaper** from `/sdcard/Download/DevTV/walls/`
- Only **your apps** (YouTube, Netflix, VLC, …) — see `default_apps.json`
- **Light** (~few MB, no ads, no extra rows)
- **Home** launcher (`com.devdock.tvlauncher`)

Source: `devdock-launcher/` (Kotlin).

## Install on TV (from laptop)

**Option A — scripts only (no git):**

```bash
mkdir -p ~/tv-beautify && cd ~/tv-beautify
curl -fsSL -o fetch-devdock-source.sh \
  "https://raw.githubusercontent.com/hafizumair74/cart/cursor/tv-beautify-launcher-8673/tv-beautify/fetch-devdock-source.sh"
curl -fsSL -o build-devdock.sh \
  "https://raw.githubusercontent.com/hafizumair74/cart/cursor/tv-beautify-launcher-8673/tv-beautify/build-devdock.sh"
curl -fsSL -o install-devdock.sh \
  "https://raw.githubusercontent.com/hafizumair74/cart/cursor/tv-beautify-launcher-8673/tv-beautify/install-devdock.sh"
chmod +x fetch-devdock-source.sh build-devdock.sh install-devdock.sh
./fetch-devdock-source.sh    # downloads devdock-launcher/ folder
./build-devdock.sh           # SDK + APK (~5 min first time)
./install-devdock.sh 192.168.0.103
```

**Option B — full git clone:**

```bash
git clone --branch cursor/tv-beautify-launcher-8673 --depth 1 \
  https://github.com/hafizumair74/cart.git ~/cart-tv
cd ~/cart-tv/tv-beautify && chmod +x build-devdock.sh install-devdock.sh
./build-devdock.sh && ./install-devdock.sh 192.168.0.103
```

`build-devdock.sh` will auto-run `fetch-devdock-source.sh` if `devdock-launcher/` is missing.

Press **Home** → select **DevDock**.

## Customize apps

**On TV** — create `/sdcard/Download/DevTV/devdock_apps.json`:

```json
["com.netflix.ninja","org.videolan.vlc","com.google.android.youtube.tv"]
```

**On laptop** — edit `devdock-launcher/app/src/main/assets/default_apps.json`, then rebuild.

Find package names:

```bash
./discover-curated-apps.sh 192.168.0.103
```

## Wallpapers

Run `./beautiful-curated-home.sh` once for 8 wallpapers, or copy your own `.jpg` files into  
`/sdcard/Download/DevTV/walls/` on the TV.

## Wisdom Share TV

Keep stock launcher installed (`com.cvte.tv.launcher.*`). DevDock sits on top as Home.

If Home opens old UI: `./wisdom-share-fix.sh` (Projectivy accessibility) or set DevDock as default again.

## Change UI code

Edit layouts in `devdock-launcher/app/src/main/res/layout/` and `MainActivity.kt`, then:

```bash
./build-devdock.sh && ./install-devdock.sh 192.168.0.103
```
