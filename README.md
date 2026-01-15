# ReverseMouseScroll 🖱️🔄

A lightweight, native macOS CLI tool to reverse mouse scroll direction independently of the trackpad.
Designed for geeks who want **"Natural Scrolling" on Trackpad** but **"Standard Scrolling" on Mouse**.

## ✨ Features

- **Native Swift**: Built with CoreGraphics & EventTap. Near-zero CPU usage.
- **Smart Logic**: Only reverses physical mouse scroll, leaves trackpad untouched.
- **Sleep Proof**: Automatically reconnects after system sleep/wake.
- **No Dependencies**: Just a single binary.

## 🚀 One-Line Install (The Geek Way)

Copy and run this command in your Terminal:

```bash
/bin/bash -c "$(curl -fsSL [https://raw.githubusercontent.com/CyrusZhang23/ReverseMouseScroll/main/install.sh](https://raw.githubusercontent.com/CyrusZhang23/ReverseMouseScroll/main/install.sh))"
```

## 🛠 Usage

Once installed, the service runs in the background automatically.

**Check status:**
```bash
ReverseMouseScroll --status
```

**Uninstall:**
```bash
ReverseMouseScroll --uninstall
```

## 📄 License

MIT License
