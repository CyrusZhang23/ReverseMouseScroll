# ReverseMouseScroll 🖱️

A lightweight macOS CLI tool that reverses mouse scroll wheel direction **without affecting the trackpad or Magic Mouse**.

Runs as a background service, survives sleep/wake cycles, and persists across reboots.

---

## Install via Homebrew

```bash
brew tap CyrusZhang23/reversemousescroll
brew install reversemousescroll
```

Then run the setup:

```bash
ReverseMouseScroll --install
```

---

## Setup

When you run `--install`, it will:

1. Copy the binary to `~/Library/Application Support/ReverseMouseScroll/`
2. Register a launchd service (auto-start on login)
3. Open Finder highlighting the installed binary
4. Open **System Settings → Privacy & Security → Accessibility**

**Drag the highlighted file into the Accessibility list and enable it**, then press Enter to finish.

> **Note:** If an old entry already exists in Accessibility, remove it first (click `−`), then re-add.

---

## Commands

| Command | Description |
|---------|-------------|
| `--install` | Install and start the background service |
| `--uninstall` | Stop the service and remove all files |
| `--status` | Show whether the service is running |
| `--show` | Show current scroll direction config |
| `--setreverse` | Change scroll direction (see below) |
| `--run` | Run in foreground for debugging (Ctrl+C to stop) |

### `--setreverse` usage

Set X and Y axes independently. Both can be changed in one command.

```bash
# Reverse vertical scroll (most common — matches Windows-style)
ReverseMouseScroll --setreverse y reverse

# Restore vertical to normal
ReverseMouseScroll --setreverse y normal

# Reverse horizontal scroll
ReverseMouseScroll --setreverse x reverse

# Set both at once
ReverseMouseScroll --setreverse y reverse x normal
```

Valid values: `normal` | `reverse`

Changes take effect immediately — no need to restart the service.

### `--show` output

```
X-Axis: Normal ➡️
Y-Axis: Reverse 🔄
```

### `--status` output

```
Status: Running
Status: Installed (Stopped)
Status: Not Installed
```

---

## Default Behavior

| Axis | Default |
|------|---------|
| Y (vertical) | `reverse` |
| X (horizontal) | `normal` |

---

## How It Works

- Uses `CGEventTap` to intercept scroll wheel events at the session level
- Detects event source: `isContinuous == 0` means physical mouse wheel → applies reversal; trackpad and Magic Mouse use continuous events → passed through unchanged
- Config is stored in `UserDefaults` and read on every event, so `--setreverse` updates take effect instantly without restarting
- The launchd service uses `KeepAlive: true` to auto-restart on crash
- On sleep/wake, the event tap is automatically rebuilt

---

## Uninstall

```bash
ReverseMouseScroll --uninstall
```

This stops the service, removes the launchd plist, and deletes the binary from Application Support. After uninstalling via Homebrew:

```bash
brew uninstall reversemousescroll
brew untap CyrusZhang23/reversemousescroll
```

Then manually remove the entry from **System Settings → Privacy & Security → Accessibility**.

---

## Build from Source

Requires Xcode 14+ and macOS 12+.

```bash
git clone https://github.com/CyrusZhang23/ReverseMouseScroll.git
cd ReverseMouseScroll
swift build -c release
.build/release/ReverseMouseScroll --install
```

---

## License

MIT
