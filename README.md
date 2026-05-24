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

---

<div align="center" style="background: radial-gradient(circle, rgba(245,74,42,0.08) 0%, transparent 80%); padding: 28px; border-radius: 20px;">
  <!-- System Sweep / Optimizer Spark (CSS SVG) -->
  <svg width="200" height="50" viewBox="0 0 200 50" fill="none" xmlns="http://www.w3.org/2000/svg" style="margin-bottom: 8px;">
    <style>
      .sweep-ray {
        stroke: #F54A2A;
        stroke-width: 1.5;
        stroke-linecap: round;
        stroke-dasharray: 8 20;
        animation: laserSweep 3s infinite linear;
      }
      .sparkle-node {
        fill: #F54A2A;
        animation: sparkTwinkle 1.5s infinite alternate ease-in-out;
        transform-origin: center;
      }
      @keyframes laserSweep {
        0% { stroke-dashoffset: 0; }
        100% { stroke-dashoffset: 56; }
      }
      @keyframes sparkTwinkle {
        0% { transform: scale(0.6) rotate(0deg); opacity: 0.5; filter: drop-shadow(0 0 1px #F54A2A); }
        100% { transform: scale(1.1) rotate(45deg); opacity: 1; filter: drop-shadow(0 0 6px #F54A2A); }
      }
    </style>
    <!-- Sweeping Laser Optimizer path -->
    <path class="sweep-ray" d="M20,25 C60,10 140,40 180,25" />
    
    <!-- Clean System Spark Nodes -->
    <g transform="translate(100, 25)">
      <polygon class="sparkle-node" points="0,-8 2,-2 8,0 2,2 0,8 -2,2 -8,0 -2,-2" />
    </g>
    <g transform="translate(50, 15)">
      <polygon class="sparkle-node" points="0,-5 1.5,-1.5 5,0 1.5,1.5 0,5 -1.5,1.5 -5,0 -1.5,-1.5" style="animation-delay: -0.5s;" />
    </g>
    <g transform="translate(150, 35)">
      <polygon class="sparkle-node" points="0,-5 1.5,-1.5 5,0 1.5,1.5 0,5 -1.5,1.5 -5,0 -1.5,-1.5" style="animation-delay: -1.0s;" />
    </g>
  </svg>
  
  <p style="font-family: 'Sora', sans-serif; font-size: 13px; font-weight: 600; color: #F54A2A; margin: 0; letter-spacing: 0.05em;">
    built by anuj with ❤️ to the electric energy of the killers' "mr. brightside"
  </p>
</div>
