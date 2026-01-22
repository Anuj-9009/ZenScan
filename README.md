# ZenScan - macOS System Maintenance Utility

A high-performance CleanMyMac-style system maintenance utility built with **Swift** and **SwiftUI** for macOS 14+.

![ZenScan Dashboard](docs/dashboard.png)

## Features

### 🔍 Smart Scan
One-click comprehensive system analysis covering junk files, applications, browser data, and startup items.

### 🗑️ System Junk Cleaner
- System & User Caches
- User Logs
- Broken Preferences

### 📦 Uninstaller
- Deep uninstall with container cleanup
- App size calculation including `~/Library` data
- Search and sort by size/name

### 🔒 Privacy Protector
- Safari & Chrome support
- Clear history, cookies, and cache
- Browser running detection

### ⚡ Optimization
- Manage Login Items
- View Background Processes
- Launch Agents control

## Design

- **Deep Space Blue** (`#0B1426`) - Backgrounds
- **Frost White** (`#F8FAFC`) - Text & highlights
- **Emerald Green** (`#10B981`) - Accents & success states
- Glassmorphism UI with SF Symbols

## Requirements

- macOS 14.0+
- Xcode 15+
- Full Disk Access (for scanning protected directories)

## Build

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ZenScan.git
cd ZenScan

# Build DMG
./build_dmg.sh
```

The DMG will be saved to `~/Downloads/ZenScan.dmg`

## Architecture

```
MVVM with System Agents
├── Views (SwiftUI)
├── ViewModels (State management)
├── Models (Data structures)
└── Services/Agents (File system operations)
```

## License

MIT License - See [LICENSE](LICENSE) for details.
