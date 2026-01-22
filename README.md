# ZenScan v2.0 - macOS System Maintenance Utility

A high-performance CleanMyMac-style system maintenance utility built with **Swift** and **SwiftUI** for macOS 14+.

![ZenScan Dashboard](docs/dashboard.png)

## 🆕 What's New in v2.0

- **Large Files Finder** - Find and remove files over 50MB/100MB/500MB/1GB
- **Duplicate Files Detector** - SHA256-based duplicate detection
- **Xcode Cache Cleaner** - Clean DerivedData, Archives, Simulators
- **Menu Bar Widget** - Quick access with live system stats
- **System Monitor** - Real-time CPU, RAM, and Disk usage
- **Onboarding Flow** - First-launch tutorial for Full Disk Access
- **Settings Panel** - Dark mode, scheduled cleaning, safety options
- **Custom App Icon** - Beautiful emerald green sparkle design
- **Confetti Animations** - Success celebration effects

## Features

### 🔍 Smart Scan
One-click comprehensive system analysis covering junk files, applications, browser data, and startup items.

### 🗑️ System Junk Cleaner
- System & User Caches
- User Logs
- Broken Preferences

### 📦 Large Files Finder
- Configurable size thresholds (50MB - 1GB)
- Sort by size or name
- File type icons

### 📄 Duplicate Finder
- Fast SHA256 hash-based detection
- Smart "original" file detection
- Wasted space calculation

### 🔨 Xcode Cleaner
- DerivedData cleanup
- Archives management
- Simulator data
- Swift Package cache

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

| Token | Value | Usage |
|-------|-------|-------|
| Deep Space Blue | `#0B1426` | Backgrounds |
| Frost White | `#F8FAFC` | Text & highlights |
| Emerald Green | `#10B981` | Accents & success |

**No purple hues used anywhere.**

## Requirements

- macOS 14.0+
- Xcode 15+ (for building)
- Full Disk Access (for scanning protected directories)

## Build

```bash
# Clone the repository
git clone https://github.com/Anuj-9009/ZenScan.git
cd ZenScan

# Build DMG
./build_dmg.sh
```

The DMG will be saved to `~/Downloads/ZenScan.dmg`

## Architecture

```
MVVM with System Agents (37 Swift files)
├── Models (6 files)
├── ViewModels (8 files) 
├── Views (12 files)
└── Services/Agents (11 files)
```

## License

MIT License - See [LICENSE](LICENSE) for details.
