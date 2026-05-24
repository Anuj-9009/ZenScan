# ZenScan 🧹🍏

<p>
  <img src="https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white" alt="Swift" />
  <img src="https://img.shields.io/badge/mac%20os-000000?style=for-the-badge&logo=macos&logoColor=F0F0F0" alt="macOS" />
</p>

ZenScan is a high-performance, native macOS System Maintenance and Diagnostics Utility. Built entirely in Swift and SwiftUI, it stands as a lightweight, lightning-fast alternative to bloated disk cleaners like CleanMyMac. Operating directly on macOS system APIs without heavy Electron wrappers, ZenScan provides real-time diagnostic monitoring and deep cache cleanup while operating within the strict security boundaries of macOS sandboxing.

---

## ✨ Features

- **🧹 Deep System Cleanup:** Safely sweeps system logs, user caches, Xcode DerivedData, build remnants, and uninstalled application trails.
- **🔍 Active Process Auditor:** Tracks high-resource macOS background system daemons (such as `mediaanalysisd`, `modelcatalogd`, and `mobileassetd`) to reclaim CPU overhead.
- **🚀 Native Performance System:** Written in pure Swift using standard native Frameworks (AppKit, Foundation, and SwiftUI) for zero RAM overhead.
- **🎨 Translucent Cupertino Design:** A gorgeously polished translucent interface utilizing macOS glassmorphism effects (`.background(.ultraThinMaterial)`) that integrates perfectly into macOS Sonoma/Sequoia.
- **🔒 Full Sandbox Compatibility:** Implements secure File Access Bookmarks, requesting explicit User permission before touching secure user paths.

---

## 🧠 Smart System Diagnostics & Clean Algorithms

ZenScan uses custom low-level Darwin API bindings to evaluate local file trees:
1. **Vibrant Directory Sweeping:**
   - Instead of standard slow shell commands like `du -sh`, ZenScan uses high-performance `NSDirectoryEnumerator` with pre-cached property keys (`.fileSizeKey`, `.isDirectoryKey`).
   - Runs in parallel using Grand Central Dispatch (GCD) under a high-priority user-interactive utility queue, resolving millions of files in under 3 seconds.
   - Evaluates system lock files and standard plist preferences to prevent sweeping directories currently in use by active system processes.

2. **System Daemon Tracking:**
   - Reads Darwin process tables directly using the standard Apple `sysctl` kernel APIs.
   - Polls active processes at `1Hz`, isolating resource-heavy system indexers.
   - Features a quick-kill toggle using Darwin signals (`SIGTERM` / `SIGKILL`) with helper authorization steps to release frozen memory blocks safely.

---

## 🏗️ Architecture & SwiftUI Flow

```
              ┌─────────────────────────────────────┐
              │           SwiftUI App View          │
              │  (Vibrant translucent windows)     │
              └──────────────────┬──────────────────┘
                                 │ (User Interactions)
                                 ▼
              ┌─────────────────────────────────────┐
              │     Scan/Diagnostics Coordinator    │
              │   (GCD queue scheduling control)    │
              └──────────────────┬──────────────────┘
                                 │
         ┌───────────────────────┴───────────────────────┐
         ▼                                               ▼
┌─────────────────────────────────┐             ┌─────────────────────────────────┐
│     Disk Pruning Engine         │             │     Process Auditor Engine      │
│  (NSDirectoryEnumerator Core)   │             │   (sysctl process listings)     │
└─────────────────────────────────┘             └─────────────────────────────────┘
```

- **Memory Leak Protection**: Avoids caching long arrays of file paths in memory; files are swept iteratively on the GCD worker thread and processed sequentially.
- **Apple Sandbox Compliance**: Automatically saves secure folders to Apple’s Security-Scoped Bookmarks, enabling subsequent cleanups without repeating file-dialog user approvals.

---

## 🚀 Complete Setup & Build Instructions

### Prerequisites
- A Mac computer running **macOS 13.0 (Ventura)** or later
- **Xcode 15+** installed from the Mac App Store
- Standard Apple developer credentials (or local signing configured to "Sign to Run Locally")

### 💻 Compilation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Anuj-9009/ZenScan.git
   cd ZenScan
   ```

2. **Open the project in Xcode:**
   ```bash
   open ZenScan.xcodeproj
   ```

3. **Configure Permissions:**
   - In Xcode, select the `ZenScan` project in the sidebar.
   - Navigate to **Signing & Capabilities**.
   - Ensure the app is configured with **App Sandbox** enabled.
   - For complete sweeps, ensure `User Selected Files` is set to `Read/Write` access.

4. **Run the application:**
   - Choose your Mac as the active build target.
   - Press `Cmd + R` to compile, launch, and run!

---

<div align="center" style="margin-top: 40px;">
  <img src="assets/footer-v2.svg" width="100%" alt="footer">
</div>
<p style="font-family: 'Sora', sans-serif; font-size: 13px; font-weight: 600; color: #F54A2A; margin: 0; text-align: center;">
  built by ANUJ with ❤️ to the electric energy of the killers' 'Mr. Brightside'
</p>
