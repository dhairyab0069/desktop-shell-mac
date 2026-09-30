// swift-tools-version:5.10
import PackageDescription

// Desktop Shell: background services that restyle the macOS desktop, like parts of an OS.
// Each is its own small app, started at login by launchd and restarted if it crashes:
//   XPTaskbar       a Windows XP taskbar + Start menu in place of the Dock, the Desktop Settings
//                   menu, the Downloads window, and the window tiler that keeps apps clear
//   DesktopFolders  iOS-style folders on the desktop
//   DesktopWidgets  the floating widget panel (Now Playing, calendar, battery, CPU/memory, storage)
//   DesktopHotkeys  ⌘⌃T → Ghostty, and a tap of ⌥ Option → Start
// ShellKit is the code they share (look, desktop windows, settings, the tiling map).
let package = Package(
    name: "DesktopShell",
    platforms: [.macOS("14.4")],
    targets: [
        .target(name: "ShellKit", path: "Sources/ShellKit"),
        .executableTarget(name: "XPTaskbar", dependencies: ["ShellKit"], path: "Sources/XPTaskbar"),
        .executableTarget(name: "DesktopFolders", dependencies: ["ShellKit"], path: "Sources/DesktopFolders"),
        .executableTarget(name: "DesktopWidgets", dependencies: ["ShellKit"], path: "Sources/DesktopWidgets"),
        .executableTarget(name: "DesktopHotkeys", dependencies: ["ShellKit"], path: "Sources/DesktopHotkeys"),
    ]
)
