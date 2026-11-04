# TV launcher options (1GB Wisdom Share / SMART_TV)

| Launcher | Look | Simple? | RAM | Best for |
|----------|------|---------|-----|----------|
| **[Vibe](https://github.com/maydings/vibe-launcher)** | Apple TV–like dock + backdrops | Yes | Light | **Default pick** — minimal, pretty |
| **[Couchy](https://github.com/conreo/couchy-launcher)** | Glass dock / carousel / grid | Yes | Light | One-screen, private, no network |
| **[Arc](https://github.com/meddouribadis/arclauncher)** | Premium grid, themes | Medium | Medium | Bigger tiles, watch-next row |
| **Projectivy** | Very customizable | No (many menus) | Heavy | Power users, not 1GB |
| **FLauncher** | Basic rows | No (shows all apps) | Light | Avoid if you want minimal |

**Never remove or disable** (boot / Home can break):

- `com.cvte.tv.launcher.space`
- `com.cvte.tv.launcher.mars`
- Any `com.cvte.tv.launcher.*` stock package

You can **uninstall sideloaded** launchers (FLauncher, Projectivy, old trials).

## Commands

List what’s installed:

```bash
./launcher-manage.sh 192.168.0.103 list
```

Try **Couchy** and remove old sideloaded launchers:

```bash
INSTALL=couchy REMOVE_OLD=1 ./launcher-manage.sh 192.168.0.103
```

Try **Arc**:

```bash
INSTALL=arc REMOVE_OLD=1 ./launcher-manage.sh 192.168.0.103
```

Keep **Vibe**, remove FLauncher + Projectivy only:

```bash
KEEP=vibe REMOVE_OLD=1 ./launcher-manage.sh 192.168.0.103
```
