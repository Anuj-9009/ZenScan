# ZenScan 🧹🍏

![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)
![macOS](https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0)

ZenScan is a native macOS System Maintenance Utility designed as a lightweight, highly-performant alternative to CleanMyMac. Built entirely in Swift and SwiftUI, it provides deep system cleaning, performance monitoring, and background daemon management.

![Demo GIF](https://via.placeholder.com/800x400.png?text=Insert+Demo+GIF+Here)

## ✨ Features
* **Smart Cleanup:** Safely purges deep system caches, uninstalled app remnants, and temporary Xcode build data.
* **Process Monitor:** Real-time analysis of resource-intensive daemons (like `mediaanalysisd` and `modelcatalogd`).
* **Native Performance:** Uses low-level macOS APIs (AppKit / Foundation) instead of wrapping a web app in Electron.
* **Beautiful UI:** A modern, translucent SwiftUI interface that feels perfectly at home on macOS Sonoma/Sequoia.

## 🏗️ Architecture
* **SwiftUI Frontend:** Uses modern declarative views with `ObservableObject` for real-time system state updates.
* **Core Foundation Bindings:** Directly interfaces with macOS standard libraries for disk I/O and process fetching to minimize overhead.
* **Sandboxing:** Designed to run with minimal necessary privileges, requesting full disk access only when deep cleaning is invoked.

## 🚀 Getting Started

### Prerequisites
* macOS 13.0+
* Xcode 15+

### Build Instructions
1. Clone the repository: `git clone https://github.com/Anuj-9009/ZenScan.git`
2. Open `ZenScan.xcodeproj` in Xcode.
3. Select your local Mac as the build target.
4. Hit `Cmd + R` to build and run.
